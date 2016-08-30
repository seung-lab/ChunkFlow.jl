using EMIRT
using DataStructures

function ef_crop!( c::DictChannel,
                params::OrderedDict{Symbol, Any},
                inputs::OrderedDict{Symbol, Any},
                outputs::OrderedDict{Symbol, Any})
    info("-----------crop-------------")
    for (k,v) in inputs
        @assert haskey(outputs, k)
        chk = fetch(c, v)
        chk = crop_border!(chk, params[:cropMarginSize])
        put!(c, outputs[k], chk)
    end
end
