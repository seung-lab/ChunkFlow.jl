using EMIRT
using Agglomeration
using Process
using DataStructures

export ef_agglomeration!

"""
edge function of agglomeration
"""
function ef_agglomeration!( c::DictChannel, e::Edge )
    println("------------start agg-----------------")
    chk_sgm = fetch(c, e.inputs[:sgm])
    chk_aff = fetch(c, e.inputs[:aff])

    # check it is an affinity map
    # and segmentation with mst
    @assert isa(chk_sgm.data, Tsgm)
    @assert isa(chk_aff.data, Taff)

    # run watershed
    dend, dendValues = Process.forward(chk_aff.data, chk_sgm.data.seg)
    @show dend
    @show dendValues
    chk_sgm.data = Tsgm(chk_sgm.data.seg, dend, dendValues)
    #chk_sgm.data = sgm

    # put output to channel
    put!(c, e.outputs[:sgm], chk_sgm)

    println("--------------agg end--------------")
end
