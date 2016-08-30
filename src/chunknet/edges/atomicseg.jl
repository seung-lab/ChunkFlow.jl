using Watershed

"""
edge function of watershed to produce atomic seg
"""
function ef_atomicseg!( c::DictChannel,
                params::OrderedDict{Symbol, Any},
                inputs::OrderedDict{Symbol, Any},
                outputs::OrderedDict{Symbol, Any})
    chk_aff = take!(c, inputs[:aff])
    @show size(chk_aff.data)
    # check it is an affinity map
    @assert isa(chk_aff.data, Taff)

    # use percentage threshold
    b, count = hist(aff[:], 20000)
    low  = percent2thd(b, count, params[:low])
    high = percent2thd(b, count, params[:high])
    thds = Vector{Tuple}()
    for st in params[:thresholds]
        push!(thds, tuple(st[:size], percent2thd(b, count, st[:threshold])))
    end
    dust = params[:dust]

    # watershed
    println("watershed...")
    seg = atomicseg(chk_aff.data, low, high, thds, dust)
    # create chunk and put into channel
    chk_seg = Chunk(seg, chk_aff.origin, chk_aff.voxelsize)
    put!(c, outputs[:seg], chk_seg)
    # put the affinity map back
    put!(c, inputs[:aff], chk_aff)
end
