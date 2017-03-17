
function checkexist( c::DictChannel,
                params::OrderedDict{Symbol, Any},
                inputs::OrderedDict{Symbol, Any},
                outputs::OrderedDict{Symbol, Any})
    chk_img = fetch(c, inputs[:referenceChunk])
    origin = chk_img.origin
    origin .+= params[:outOffset]
    sz = params[:outChunkSize]
    # the file should exist
    fileName = params[:prefix]
    for i in eachindex(origin)
        fileName *= "_$(origin[i])-$(origin[i]+sz[i]-1)"
    end
    fileName *= params[:suffix]*".h5"

    if !isfile(fileName)
        warn("file do not exist: $(fileName)")
        prinln("file do not exist: $(fileName)")
    end
end
