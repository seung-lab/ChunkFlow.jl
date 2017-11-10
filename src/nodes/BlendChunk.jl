module BlendChunk

# save chunk from dictchannel to BigArrays
using ..Nodes 
using BigArrays
using BigArrays.Chunks
using BigArrays.H5sBigArrays
using GSDicts
using S3Dicts
using DataStructures
using BOSSArrays
using CloudVolume

export NodeBlendChunk, run

struct NodeBlendChunk <: AbstractIONode end 

"""
node function of blendchunk
"""
function Nodes.run(x::NodeBlendChunk, c::Dict{String, Channel},
                   nodeConf::NodeConf)
    params = nodeConf[:params]
    inputs = nodeConf[:inputs]
    outputs = nodeConf[:outputs]
    # get chunk
    chk = take!(c[inputs[:chunk]])
    @show size(chk)

    N = ndims(chk)
    globalRange = CartesianRange(
            CartesianIndex((ones(Int,N).*typemax(Int)...)),
            CartesianIndex((zeros(Int,N)...)))
    if contains(params[:backend], "h5s")
        ba = H5sBigArray(expanduser(outputs[:bigArrayDir]);)
    elseif contains(params[:backend], "gs")
        d = GSDict( params[:outputPath] )
        ba = BigArray(d)
    elseif contains(params[:backend], "s3")
        d = S3Dict( params[:outputPath] )
        ba = BigArray(d)
    elseif contains(params[:backend], "boss")
        ba = BOSSArray(
                T               = eval(Symbol(params[:dataType])),
                N               = params[:dimension],
                collectionName  = params[:collectionName],
                experimentName  = params[:experimentName],
                channelName     = params[:channelName],
                resolutionLevel = params[:resolutionLevel])
    elseif contains(params[:backend], "olume")
        ba = CloudVolumeWarpper( params[:outputPath]; is1based=true )
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
    elseif isa(ba, CloudVolumeWarpper)
        println("using CloudVolumeWarpper")
        ba[Chunks.global_range( chk )[1:3]...] = Chunks.get_data(chk)
        return 
    else
        warn("unknown type of ba: $(typeof(ba))")
    end
    @show get_offset(chk)
    @assert mod(get_offset(chk), [chunkSize...]) == zeros(eltype(chk), ndims(chk))

    blendchunk(ba, chk)
end

end # end of module
