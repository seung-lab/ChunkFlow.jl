using Watershed
using EMIRT

"""
edge function of watershed to produce atomic seg
"""
function ef_atomicseg!( c::DictChannel,
                params::OrderedDict{Symbol, Any},
                inputs::OrderedDict{Symbol, Any},
                outputs::OrderedDict{Symbol, Any})
    chk_aff = fetch(c, inputs[:aff])
    @show size(chk_aff.data)
    # check it is an affinity map
    @assert isa(chk_aff.data, AffinityMap)

    # make the threshold data structure
    thds = Vector{Tuple}()
    for st in params[:thresholds]
        push!(thds, tuple(st[:size], st[:threshold]))
    end

    # watershed
    println("watershed...")
    seg = atomicseg(chk_aff.data,   params[:low], params[:high],
                    thds, params[:dust];
                    is_threshold_relative=params[:isThresholdRelative])

    # create chunk and put into channel
    chk_seg = Chunk(seg, chk_aff.origin, chk_aff.voxelSize)

    if haskey(params, :cropSegMarginSize)
        stt = time()
        println("start crop segmentation and relabel using connected component analysis...")
        chk_seg = BigArrays.crop_border(chk_seg, params[:cropSegMarginSize])
        # relabel segments in case some segments was broken by cropping
        segid1N!(chk_seg.data)
        chk_seg.data = relabel_seg(chk_seg.data)
        segid1N!(chk_seg.data)
        println("time cost of cropping and relabelling: $((time()-stt)/60) min")
    end

    put!(c, outputs[:seg], chk_seg)
end
