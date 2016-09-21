
"""
edge function of remove
"""
function ef_remove!( c::DictChannel,
                params::OrderedDict{Symbol, Any},
                inputs::OrderedDict{Symbol, Any},
                outputs::OrderedDict{Symbol, Any})
    for data in inputs[:datas]
        tmp = take!(c, data)
        tmp = nothing
    end 
end
