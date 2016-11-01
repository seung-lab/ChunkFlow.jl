# save chunk from dictchannel to BigArrays

using BigArrays
using BigArrays.H5sBigArrays
using DataStructures

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
                        globalOffset = (params[:globalOffset]...),
                        globalRange = globalRange
                        )
        blendchunk(ba, chk)
    else
        error("unsupported bigarray backend: $(params[:backend])")
    end
end
