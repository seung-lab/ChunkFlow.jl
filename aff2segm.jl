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
    # remap to uniform distribution
    if d["is_remap"]
        # aff = aff2uniform(aff)
        # seg, dend, dendValues = aff2segm(aff, d["low"], d["high"], d["thresholds"], d["dustsize"])
        low  = rthd2athd(aff, d["low"])
        high = rthd2athd(aff, d["high"])
        seg, dend, dendValues = aff2segm(aff, low, high, d["thresholds"], d["dustsize"])
    else
        seg, dend, dendValues = aff2segm(aff, d)
    end

    # aggromeration
    if pd["agg"]["is_agg"]
        dend, dendValues = Process.forward(aff, seg)
    end
    # save seg and mst
    save_segm(pd["gn"]["fsegm"], seg, dend, dendValues)
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
