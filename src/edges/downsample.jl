function nf_downsample( c::DictChannel,
                params::OrderedDict{Symbol, Any},
                inputs::OrderedDict{Symbol, Any},
                outputs::OrderedDict{Symbol, Any})
    for (k,v) in inputs
        @assert haskey(outputs, k)
        chk = take!(c, v)
        chk = BigArrays.Chunks.downsample(chk; scale = params[:scale])
        put!(c, outputs[k], chk)
    end
end
