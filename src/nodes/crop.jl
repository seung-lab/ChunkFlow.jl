using DataStructures

function nf_crop!( c::DictChannel,
                params::OrderedDict{Symbol, Any},
                inputs::OrderedDict{Symbol, Any},
                outputs::OrderedDict{Symbol, Any})
    for (k,v) in inputs
        @assert haskey(outputs, k)
        chk = take!(c, v)
        chk = BigArrays.Chunks.crop_border(chk, params[:cropMarginSize])
        put!(c, outputs[k], chk)
    end
end
