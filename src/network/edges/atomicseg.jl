using Watershed
using DataStructures

export ef_atomicseg

"""
edge function of watershed to produce atomic seg
"""
function ef_atomicseg( c::DictChannel,
                params::OrderedDict{Symbol, Any},
                inputs::OrderedDict{Symbol, Any},
                outputs::OrderedDict{Symbol, Any})
    chk_aff = fetch(c, inputs[:aff])
    aff = chk_aff.data
    @show size(aff)
    # check it is an affinity map
    @assert isa(aff, Taff)

    # use percentage threshold
    b, count = hist(aff[:], 100000)
    low  = percent2thd(b, count, params[:low])
    high = percent2thd(b, count, params[:high])
    thds = Vector{Tuple}()
    for st in params[:thresholds]
        push!(thds, tuple(st[:size], percent2thd(b, count, st[:threshold])))
    end
    dust = params[:dust]

    # watershed
    println("watershed...")
    seg = atomicseg(aff, low, high, thds, dust)
    # create chunk and put into channel
    chk_seg = Chunk(seg, chk_aff.origin, chk_aff.voxelsize)
    put!(c, outputs[:seg], chk_seg)
end
