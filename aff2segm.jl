using HDF5
using EMIRT
using Watershed

export aff2segm

function rt2dend(rt)
    # get dendrogram
    println("get mst for omnifycation...")
    N = length(rt)

    dendValues = zeros(Float32, N)
    dend = zeros(UInt32, N,2)

    for i in 1:N
        t = rt[i]
        dendValues[i] = t[1]
        dend[i,1] = t[2]
        dend[i,2] = t[3]
    end
    return dend, dendValues
end

"""
transform affinity map to segmentation with mst
"""
function aff2segm(d::Dict{AbstractString, Any})
    if !d["is_ws"]
        return
    end
    # read affinity map
    print("reading affinity map...")
    aff = h5read(d["faff"], "/main")
    println("done!")

    # watershed
    # exchange x and z channel
    if d["is_exchange_aff_xz"]
        exchangeaffxz!(aff)
    end

    if contains(d["remap_type"], "uniform")
        # remap the affinity to uniform distribution, will do sorting
        aff = aff2uniform(aff)
        seg, dend, dendValues = aff2segm(aff, d["low"], d["high"], d["thresholds"], d["dustsize"])
    elseif contains(d["remap_type"], "percent")
        # use percentage threshold
        e, count = hist(aff[:], 10000)
        low  = percent2thd(e, count, d["low"])
        high = percent2thd(e, count, d["high"])
        thds = Vector{Tuple}()
        for tp in d["thresholds"]
            push!(thds, tuple(tp[1], percent2thd(e, count, tp[2])))
        end
        seg, dend, dendValues = aff2segm(aff, low, high, thds, d["dustsize"])
    else
        # use absolute threshold
        seg, dend, dendValues = aff2segm(aff, d)
    end

    # aggromeration
    if d["agg_mode"]=="mean"
        dend, dendValues = Process.forward(aff, seg)
    end
    # save seg and mst
    save_segm(d["fsegm"], seg, dend, dendValues)
end

function aff2segm(aff::Taff, d::Dict{ASCIIString, Any})
    return aff2segm(aff, d["low"], d["high"], d["thresholds"], d["dustsize"])
end

function aff2segm(aff::Taff, low::AbstractFloat, high::AbstractFloat, thresholds=[(1000,0.3)], dustsize=1000)
    # watershed
    println("watershed...")
    seg, rt = watershed(aff, low, high, thresholds, dustsize);
    dend, dendValues = rt2dend(rt)
    return seg, dend, dendValues
end

function save_segm(fsegm, seg, dend, dendValues)
    # remove existing file
    if isfile(fsegm)
        rm(fsegm)
    end
    # save segments and mst
    println("save the segments and the mst...")
    h5write(fsegm, "/dend", dend)
    h5write(fsegm, "/dendValues", dendValues)
    h5write(fsegm, "/main", seg)
end
