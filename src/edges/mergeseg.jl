
"""
edge function of watershed
"""
function ef_mergeseg!( c::DictChannel,
                params::OrderedDict{Symbol, Any},
                inputs::OrderedDict{Symbol, Any},
                outputs::OrderedDict{Symbol, Any})
    chk_sgm = fetch(c, inputs[:sgm])

    # watershed
    println("merge segmentation...")
    seg = merge!(chk_sgm.data, params[:threshold])

    put!(c, outputs[:seg], Chunk(seg, chk_sgm.origin, chk_sgm.voxelSize))
end
