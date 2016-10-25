
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
    merge!(chk_sgm.data, params[:threshold])

    put!(c, outputs[:sgm], chk_sgm)
end
