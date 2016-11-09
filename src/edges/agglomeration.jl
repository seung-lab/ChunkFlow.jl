using Agglomeration
using Process
using EMIRT

"""
edge function of agglomeration
"""
function ef_agglomeration!( c::DictChannel,
                    params::OrderedDict{Symbol, Any},
                    inputs::OrderedDict{Symbol, Any},
                    outputs::OrderedDict{Symbol, Any})
    chk_seg = fetch(c, inputs[:seg])
    if params[:isDeleteAff]
        chk_aff = take!(c, inputs[:aff])
    else
        chk_aff = fetch(c, inputs[:aff])
    end

    # check it is an affinity map
    # and segmentation with mst
    @assert isa(chk_seg.data, Segmentation)
    @assert isa(chk_aff.data, AffinityMap)
    # @assert size(chk_aff)[1:3] == size(chk_seg)

    if haskey(params, :maskAffinityMarginSize)
        mask_margin!( chk_aff.data, params[:maskAffinityMarginSize])
    end

    if haskey(params, :cropSegMarginSize)
        chk_seg_out = BigArrays.crop_border(chk_seg, params[:cropSegMarginSize])
        segids = Set{eltype(chk_seg_out.data)}()
        for i in eachindex(chk_seg_out.data)
           push!(segids, chk_seg_out.data[i])
        end
        segmentPairs, segmentPairAffinities = Process.forward(chk_aff.data, chk_seg.data, segids)
        sgm = SegMST(chk_seg_out.data, segmentPairs, segmentPairAffinities)
    else
        segmentPairs, segmentPairAffinities = Process.forward(chk_aff.data, chk_seg.data)
        sgm = SegMST(chk_seg.data, segmentPairs, segmentPairAffinities)
    end
    chk_sgm = Chunk(sgm, chk_aff.origin[1:3], chk_aff.voxelSize)

    # put output to channel
    put!(c, outputs[:sgm], chk_sgm)
    if params[:isDeleteAff]
      chk_aff = nothing
    end
    gc()
end
