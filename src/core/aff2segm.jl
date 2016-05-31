using HDF5
using EMIRT
using Watershed

export aff2segm

"""
transform region graph to dendrogram
"""
function rg2dend(rg::Vector)
    # get dendrogram
    println("get mst for omnifycation...")
    N = length(rg)

    dendValues = zeros(Float32, N)
    dend = zeros(UInt32, N,2)

    for i in 1:N
        t = rg[i]
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
    if contains(d["node_switch"], "off")
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
        unfaff = aff2uniform(aff)
        sgm = aff2segm(unfaff, d["low"], d["high"], d["thresholds"], d["dustsize"])
    elseif contains(d["remap_type"], "percent")
        # use percentage threshold
        e, count = hist(aff[:], 10000)
        low  = percent2thd(e, count, d["low"])
        high = percent2thd(e, count, d["high"])
        thds = Vector{Tuple}()
        for tp in d["thresholds"]
            push!(thds, tuple(tp[1], percent2thd(e, count, tp[2])))
        end
        sgm = aff2segm(aff, low, high, thds, d["dustsize"])
    else
        # use absolute threshold
        sgm = aff2segm(aff, d)
    end

    # aggromeration
    if d["agg_mode"]=="mean"
        println("mean affinity agglomeration...")
        if contains(d["agg_aff_source"], "uniform")
            # use uniform remapped affinity map
            dend, dendValues = Process.forward(unfaff, sgm.seg)
        else
            # use original affinity map
            dend, dendValues = Process.forward(aff, sgm.seg)
        end
        # create a new sgm, because Tsgm is immutable!
        @show dend
        sgm = Tsgm(sgm.seg, dend, dendValues)
    end
    # save seg and mst
    savesgm(d["fsegm"], sgm)
end

function aff2segm(aff::Taff, d::Dict{ASCIIString, Any})
    return aff2segm(aff, d["low"], d["high"], d["thresholds"], d["dustsize"])
end

function aff2segm(aff::Taff, low::AbstractFloat=0.2, high::AbstractFloat=0.8, thresholds=[(1000,0.3)], dustsize=1000)
    # watershed
    println("watershed...")
    seg, rg = watershed(aff, low, high, thresholds, dustsize)
    dend, dendValues = rg2dend(rg)
    ret = Tsgm( seg, dend, dendValues )
    return ret
end
