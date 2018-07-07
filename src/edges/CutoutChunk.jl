module CutoutChunk

import ChunkFlow.Errors: ZeroOverFlowError
using ..Edges
using OffsetArrays 
using BigArrays
#using BigArrays.H5sBigArrays
#using H5SectionsArrays
using BigArrays.BinDicts, BigArrays.GSDicts, BigArrays.S3Dicts
#using BOSSArrays
#using CloudVolume 

using ChunkFlow.Utils.Clouds 

export EdgeCutoutChunk, run
struct EdgeCutoutChunk <: AbstractIOEdge end 

"""
edge function of cutting out chunk from bigarray

example: 
{
    "params": {
        "bigArrayType": "s3",
        "start": [4897, 4897, 941],
        "cutoutSize": [1120, 1120, 126],
        "nonzeroRatioThreshold": 0.00,
        "inputPath": "path/to/input/layer/4_4_40"
    },
    "outputs": {
        "data": "img"
    }
}
"""
function Edges.run(x::EdgeCutoutChunk, c::Dict{String, Channel}, edgeConf::EdgeConf)
    params = edgeConf[:params]
    outputs = edgeConf[:outputs]
    if haskey(params, :chunkSize)
        warn("should use cutoutSize rather than chunkSize for clarity!")
        params[:cutoutSize] = params[:chunkSize]
    end
   # if  contains( params[:bigArrayType], "align") || 
   #     contains( params[:bigArrayType], "Align") || 
   #     contains( params[:bigArrayType], "section")
   #     params[:registerFile] = expanduser(params[:registerFile])
   #     @assert isfile( params[:registerFile] )
   #     ba = H5SectionsArrays(params[:registerFile])
   #     params[:origin] = params[:origin][1:3]
    #elseif  contains( params[:bigArrayType], "H5" ) ||
    #        contains(params[:bigArrayType], "h5") ||
    #        contains( params[:bigArrayType], "hdf5" )
    #    ba = H5sBigArray( params[:h5sDir] )
    if ismatch(r"^gs://*", params[:inputPath])
        d = GSDict( params[:inputPath] )
        ba = BigArray( d )
    elseif ismatch(r"^s3://*", params[:inputPath])
        d = S3Dict( params[:inputPath] )
        ba = BigArray( d )
    elseif isdir(params[:inputPath])
        d = BinDict( params[:inputPath] )
        ba = BigArray( d )

   # elseif  contains( params[:bigArrayType], "boss" ) ||
   #         contains( params[:bigArrayType], "BOSS" )
   #     ba = BOSSArray(
   #             T               = eval(Symbol(params[:dataType])),
   #             N               = params[:dimension],
   #             collectionName  = params[:collectionName],
   #             channelName     = params[:channelName],
   #             resolutionLevel = params[:resolutionLevel] )
    #elseif contains( params[:bigArrayType], "olume" ) 
    #    ba = CloudVolumeWrapper( params[:inputPath]; is1based=true )
    else
      error("invalid bigarray type: $(params[:bigArrayType])")
    end

    # get range
    N = ndims(ba)
    inputOffset = params[:inputOffset]
    cutoutSize = params[:cutoutSize]

    # cutout as an OffsetArray 
    #if contains(params[:bigArrayType], "olume")
        #CloudVolume only works with 3D index
    #    data = ba[map((x,y)->x:x+y-1, origin[1:3], cutoutSize[1:3])...]
    #else
    chunk = ba[map((x,y)->x+1:x+y, inputOffset, cutoutSize)...]

    if haskey(params, :isRemoveNaN) && params[:isRemoveNaN]
        for i in eachindex(data)
            if isnan(chunk[i])
                chunk[i] = zero(eltype(chunk))
            end
        end
    end

    if haskey(params, :nonzeroRatioThreshold) && params[:nonzeroRatioThreshold] > 0.0
        data = chunk |> parent 
        nonzeroRatio = Float64(countnz(data)) / Float64(length(data))
        info("ratio of nonzero voxels in this chunk: $(nonzeroRatio)")
        
        if nonzeroRatio < params[:nonzeroRatioThreshold]
            warn("ratio of nonzeros $(nonzeroRatio) less than threshold:$(params[:nonzeroRatioThreshold]), origin: $(origin)")
            throw( ZeroOverFlowError() )
        end 
    end

    @show typeof(chunk)

    # put chunk to channel for use
    key = outputs[:chunk]
    if !haskey(c, key)
        c[key] = Channel{OffsetArray}(1)
    end 
    put!(c[key], chunk)
end

end # end of module
