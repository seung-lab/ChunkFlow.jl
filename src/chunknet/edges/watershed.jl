using Watershed
using DataStructures

"""
edge function of watershed
"""
function ef_watershed!( c::DictChannel,
                params::OrderedDict{Symbol, Any},
                inputs::OrderedDict{Symbol, Any},
                outputs::OrderedDict{Symbol, Any})
    chk_aff = take!(c, inputs[:aff])
    @show size(chk_aff.data)
    # check it is an affinity map
    @assert isa(chk_aff.data, Taff)

    # watershed
    println("watershed...")
    seg, rg = watershed(chk_aff.data, params[:low], params[:high],
                        params[:thds], params[:dust];
                        is_relative_threshold=true)
    @show rg
    @show typeof(rg)
    dend, dendValues = rg2dend(rg)
    @show dend
    sgm = Tsgm( seg, dend, dendValues )

    # create chunk and put into channel
    chk_sgm = Chunk(sgm, chk_aff.origin, chk_aff.voxelsize)
    put!(c, outputs[:sgm], chk_sgm)
    # put affnity back
    put!(c, inputs[:aff], chk_aff)

    # release memory
    sgm = nothing
    chk_sgm = nothing
    chk_aff = nothing
    gc()
end
