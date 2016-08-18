using EMIRT
using DataStructures

function ef_crop!( c::DictChannel,
                params::OrderedDict{Symbol, Any},
                inputs::OrderedDict{Symbol, Any},
                outputs::OrderedDict{Symbol, Any})
    for (k,v) in inputs
        @assert haskey(outputs, k)
        chk = fetch(c, v)
        chk = crop_border!(chk, params[:cropsize])
        put!(c, outputs[k], chk)
    end
end
