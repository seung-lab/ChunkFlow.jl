using Watershed
using DataStructures

export ef_watershed!

"""
edge function of watershed
"""
function ef_watershed!( c::DictChannel, e::Edge )
    println("-----------start watershed------------")
    chk_aff = fetch(c, e.inputs[:aff])
    aff = chk_aff.data
    @show size(aff)
    # check it is an affinity map
    @assert isa(aff, Taff)

    # use percentage threshold
    b, count = hist(aff[:], 100000)
    low  = percent2thd(b, count, e.params[:low])
    high = percent2thd(b, count, e.params[:high])
    thds = Vector{Tuple}()
    for st in e.params[:thresholds]
        push!(thds, tuple(st[:size], percent2thd(b, count, st[:threshold])))
    end
    dust = e.params[:dust]

    # watershed
    println("watershed...")
    seg, rg = watershed(aff, low, high, thds, dust)
    @show rg
    @show typeof(rg)
    dend, dendValues = rg2dend(rg)
    @show dend
    sgm = Tsgm( seg, dend, dendValues )

    # create chunk and put into channel
    chk_sgm = Chunk(sgm, chk_aff.origin, chk_aff.voxelsize)
    put!(c, e.outputs[:sgm], chk_sgm)
    println("-----------watershed end--------------")
end
