module CutoutChunk
using ..Nodes
using HDF5
using BigArrays
using BigArrays.H5sBigArrays
using BigArrays.Chunk
using H5SectionsArrays
using GSDicts, S3Dicts
using BOSSArrays

export NodeCutoutChunk, run
immutable NodeCutoutChunk <: AbstractIONode end 

"""
node function of cutting out chunk from bigarray
"""
function Nodes.run(x::NodeCutoutChunk, c::Dict{String, Channel}, nodeConf::NodeConf)
    params = nodeConf[:params]
    inputs = nodeConf[:inputs]
    outputs = nodeConf[:outputs]
    if haskey(params, :chunkSize)
        warn("should use cutoutSize rather than chunkSize for clarity!")
        params[:cutoutSize] = params[:chunkSize]
    end
    if  contains( params[:bigArrayType], "align") || 
        contains( params[:bigArrayType], "Align") || 
        contains( params[:bigArrayType], "section")
        inputs[:registerFile] = expanduser(inputs[:registerFile])
        @assert isfile( inputs[:registerFile] )
        ba = H5SectionsArrays(inputs[:registerFile])
        params[:origin] = params[:origin][1:3]
    elseif  contains( params[:bigArrayType], "H5" ) ||
            contains(params[:bigArrayType], "h5") ||
            contains( params[:bigArrayType], "hdf5" )
        ba = H5sBigArray( inputs[:h5sDir] )
    elseif contains( params[:bigArrayType], "gs" )
        d = GSDict( inputs[:path] )
        ba = BigArray( d )
    elseif contains( params[:bigArrayType], "s3" )
        d = S3Dict( inputs[:path] )
        ba = BigArray( d )
    elseif  contains( params[:bigArrayType], "boss" ) ||
            contains( params[:bigArrayType], "BOSS" )
        ba = BOSSArray(
                T               = eval(Symbol(params[:dataType])),
                N               = params[:dimension],
                collectionName  = params[:collectionName],
                channelName     = params[:channelName],
                resolutionLevel = params[:resolutionLevel] )
    else
      error("invalid bigarray type: $(params[:bigArrayType])")
    end

    # get range
    N = ndims(ba)
    if haskey(inputs, :referenceChunk)
        referenceChunk = c[inputs[:referenceChunk]]
        origin      = referenceChunk.origin[1:N]
        cutoutSize  = size(referenceChunk)[1:N]
        if length(origin) > N
            origin = origin[1:N]
            cutoutSize = cutoutSize[1:N]
        elseif length(origin) < N
            origin = [origin..., ones(typeof(origin), N-length(origin))...]
        end
    else
        origin = params[:origin][1:ndims(ba)]
        cutoutSize = params[:cutoutSize]
    end

    if haskey(params, :originOffset)
        origin .+= params[:originOffset]
    end

    # cutout as chunk
    data = ba[map((x,y)->x:x+y-1, origin, cutoutSize)...]

    if haskey(params, :isRemoveNaN) && params[:isRemoveNaN]
        ZERO = convert(eltype(data), 0)
        for i in eachindex(data)
            if isnan(data[i])
                data[i] = ZERO
            end
        end
    end

    nonzeroRatio = Float64(countnz(data)) / Float64(length(data))
    info("ratio of nonzero voxels in this chunk: $(nonzeroRatio)")
    if haskey(params, :nonzeroRatioThreshold) &&
        nonzeroRatio < params[:nonzeroRatioThreshold]
        warn("ratio of nonzeros $(nonzeroRatio) less than threshold:$(params[:nonzeroRatioThreshold]), origin: $(origin)")
        throw( ZeroOverFlowError() )
    end


    # add offset to chunk
    if haskey(params, :offset)
        origin .+= params[:offset]
    end
    @show typeof(data)
    @show origin, params[:voxelSize]
    chk = Chunk(data, origin, params[:voxelSize])

    println("cut out chunk size: $(size(data))")

    # put chunk to channel for use
    key = outputs[:data]
    if !haskey(c, key)
        c[key] = Channel{Chunk}(1)
    end 
    put!(c[key], chk)
end

end # end of module
