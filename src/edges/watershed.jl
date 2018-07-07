using Watershed
using DataStructures

"""
edge function of watershed
"""
function nf_watershed!( c::DictChannel,
                params::OrderedDict{Symbol, Any},
                inputs::OrderedDict{Symbol, Any},
                outputs::OrderedDict{Symbol, Any})
    chk_aff = fetch(c, inputs[:aff])
    @show size(chk_aff.data)
    # check it is an affinity map
    @assert isa(chk_aff.data, AffinityMap)

    # watershed
    println("watershed...")
    seg, rg = watershed(chk_aff.data;
                    low         =  params[:low],
                    high        = params[:high],
                    thresholds  = thds,
                    dust_size   = params[:dust],
                    is_threshold_relative=params[:isThresholdRelative])
    @show rg
    @show typeof(rg)
    segmentPairs, segmentPairAffinities = rg2segmentPairs(rg)
    @show segmentPairs
    sgm = SegMST( seg, segmentPairs, segmentPairAffinities )

    # create chunk and put into channel
    chk_sgm = Chunk(sgm, chk_aff.origin[1:3], chk_aff.voxelSize)
    put!(c, outputs[:sgm], chk_sgm)

    # release memory
    sgm = nothing
    chk_sgm = nothing
    chk_aff = nothing
    gc()
end
