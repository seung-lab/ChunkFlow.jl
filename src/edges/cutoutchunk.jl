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

include("../utils/Clouds.jl"); using .Clouds 

export EdgeCutoutChunk, run
struct EdgeCutoutChunk <: AbstractIOEdge end 

"""
edge function of cutting out chunk from bigarray
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
    if contains( params[:bigArrayType], "gs" )
        d = GSDict( params[:inputPath] )
        ba = BigArray( d )
    elseif contains( params[:bigArrayType], "s3" )
        d = S3Dict( params[:inputPath] )
        ba = BigArray( d )
    elseif contains( params[:bigArrayType], "bin" )
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
    offset = params[:offset]
    cutoutSize = params[:cutoutSize]

    # cutout as an OffsetArray 
    #if contains(params[:bigArrayType], "olume")
        #CloudVolume only works with 3D index
    #    data = ba[map((x,y)->x:x+y-1, origin[1:3], cutoutSize[1:3])...]
    #else
    chunk = ba[map((x,y)->x+1:x+y, offset, cutoutSize)...]

    if haskey(params, :isRemoveNaN) && params[:isRemoveNaN]
        for i in eachindex(data)
            if isnan(chunk[i])
                chunk[i] = zero(eltype(chunk))
            end
        end
    end

    nonzeroRatio = Float64(countnz(chunk)) / Float64(length(chunk))
    info("ratio of nonzero voxels in this chunk: $(nonzeroRatio)")
    if haskey(params, :nonzeroRatioThreshold) &&
        nonzeroRatio < params[:nonzeroRatioThreshold]
        warn("ratio of nonzeros $(nonzeroRatio) less than threshold:$(params[:nonzeroRatioThreshold]), origin: $(origin)")
        throw( ZeroOverFlowError() )
    end

    @show typeof(chunk)

    # put chunk to channel for use
    key = outputs[:chunk]
    if !haskey(c, key)
        c[key] = Channel{OffsetArray}(1)
    end 
    put!(c[key], chk)
end

end # end of module
