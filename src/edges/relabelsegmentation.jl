using EMIRT

"""
edge function of watershed
"""
function ef_relabelseg!( c::DictChannel,
                params::OrderedDict{Symbol, Any},
                inputs::OrderedDict{Symbol, Any},
                outputs::OrderedDict{Symbol, Any})
    chk_sgm = fetch(c, inputs[:sgm])

    # watershed
    println("merge segmentation...")
    chk_sgm.data = relabel_seg( chk_sgm.data )

    put!(c, outputs[:sgm], chk_sgm)
end
