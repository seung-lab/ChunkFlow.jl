using Agglomeration
using Process

"""
edge function of agglomeration
"""
function ef_agglomeration!( c::DictChannel,
                    params::OrderedDict{Symbol, Any},
                    inputs::OrderedDict{Symbol, Any},
                    outputs::OrderedDict{Symbol, Any})
    chk_seg = fetch(c, inputs[:seg])
    if params[:isdeleteaff]
        chk_aff = take!(c, inputs[:aff])
    else
        chk_aff = fetch(c, inputs[:aff])
    end

    # check it is an affinity map
    # and segmentation with mst
    @assert isa(chk_seg.data, Tseg)
    @assert isa(chk_aff.data, Taff)

    # run watershed
    dend, dendValues = Process.forward(chk_aff.data, chk_seg.data)
    sgm = Tsgm(chk_seg.data, dend, dendValues)
    chk_sgm = Chunk(sgm, chk_aff.origin, chk_aff.voxelsize)

    # put output to channel
    put!(c, outputs[:sgm], chk_sgm)

    # release memory
    chk_aff = nothing
    gc()
end
