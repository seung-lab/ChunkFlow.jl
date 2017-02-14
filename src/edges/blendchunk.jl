# save chunk from dictchannel to BigArrays

using BigArrays
using BigArrays.H5sBigArrays
using GSDicts
using S3Dicts
using DataStructures
using BOSSArrays

"""
edge function of blendchunk
"""
function ef_blendchunk(c::DictChannel,
                    params::OrderedDict{Symbol, Any},
                    inputs::OrderedDict{Symbol, Any},
                    outputs::OrderedDict{Symbol, Any} )
    # get chunk
    chk = fetch(c, inputs[:chunk])
    @show size(chk)

    N = ndims(chk)
    globalRange = CartesianRange(
            CartesianIndex((ones(Int,N).*typemax(Int)...)),
            CartesianIndex((zeros(Int,N)...)))
    if contains(params[:backend], "h5s")
        ba = H5sBigArray(expanduser(outputs[:bigArrayDir]);
                        blockSize = (params[:blockSize]...),
                        chunkSize = (params[:chunkSize]...),
                        globalOffset = (params[:globalOffset]...)
                        )
    elseif contains(params[:backend], "gs")
        d = GSDict( outputs[:path] )
        ba = BigArray(d)
    elseif contains(params[:backend], "s3")
        d = S3Dict( outputs[:path] )
        ba = BigArray(d)
    elseif contains(params[:backend], "boss")
        ba = BOSSArray(
                T               = eval(Symbol(params[:dataType])),
                N               = params[:dimension],
                collectionName  = params[:collectionName],
                channelName     = params[:channelName],
                resolutionLevel = params[:resolutionLevel])
    else
        error("unsupported bigarray backend: $(params[:backend])")
    end
    blendchunk(ba, chk)
end
