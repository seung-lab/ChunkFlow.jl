using Watershed

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
    put!(c, outputs[:seg], chk_seg)
end