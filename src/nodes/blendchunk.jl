# save chunk from dictchannel to BigArrays

using BigArrays
using BigArrays.Chunks
using BigArrays.H5sBigArrays
using GSDicts
using S3Dicts
using DataStructures
using BOSSArrays
"""
node function of blendchunk
"""
function nf_blendchunk(c::DictChannel,
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
        ba = H5sBigArray(expanduser(outputs[:bigArrayDir]);)
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
                experimentName  = params[:experimentName],
                channelName     = params[:channelName],
                resolutionLevel = params[:resolutionLevel])
    else
        error("unsupported bigarray backend: $(params[:backend])")
    end

    # make sure that the writting is aligned
    if isa(ba, BigArray)
        chunkSize = BigArrays.get_chunk_size(ba)
    elseif isa(ba, H5sBigArray)
        chunkSize = H5sBigArrays.get_chunk_size(ba)
    elseif isa(ba, BOSSArray)
    	chunkSize = (512,512,16)
    else
        warn("unknown type of ba: $(typeof(ba))")
    end
    @show get_offset(chk)
    @assert mod(get_offset(chk), [chunkSize...]) == zeros(eltype(chk), ndims(chk))

    blendchunk(ba, chk)
end
