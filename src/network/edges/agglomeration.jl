using EMIRT
using Agglomeration
using Process
using DataStructures

export ef_agglomeration!

"""
edge function of agglomeration
"""
function ef_agglomeration!( c::DictChannel,
                    params::OrderedDict{Symbol, Any},
                    inputs::OrderedDict{Symbol, Any},
                    outputs::OrderedDict{Symbol, Any})
    chk_sgm = fetch(c, inputs[:sgm])
    chk_aff = fetch(c, inputs[:aff])

    # check it is an affinity map
    # and segmentation with mst
    @assert isa(chk_sgm.data, Tsgm)
    @assert isa(chk_aff.data, Taff)

    # run watershed
    dend, dendValues = Process.forward(chk_aff.data, chk_sgm.data.seg)
    chk_sgm.data = Tsgm(chk_sgm.data.seg, dend, dendValues)

    # put output to channel
    put!(c, outputs[:sgm], chk_sgm)
end
