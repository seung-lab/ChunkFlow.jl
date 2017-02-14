using HDF5
using BigArrays
using BigArrays.H5sBigArrays
using BigArrays.AlignedBigArrays
using DVID
using DVID.ImageTileArrays
using GSDicts, S3Dicts
using BOSSArrays
"""
edge function of cutting out chunk from bigarray
"""
function ef_cutoutchunk!(c::DictChannel,
                    params::OrderedDict{Symbol, Any},
                    inputs::OrderedDict{Symbol, Any},
                    outputs::OrderedDict{Symbol, Any} )
    if contains( params[:bigArrayType], "align") || contains( params[:bigArrayType], "Align")
        inputs[:registerFile] = expanduser(inputs[:registerFile])
        @assert isfile( inputs[:registerFile] )
        ba = AlignedBigArray(inputs[:registerFile])
        params[:origin] = params[:origin][1:3]
    elseif  contains( params[:bigArrayType], "H5" ) ||
            contains(params[:bigArrayType], "h5") ||
            contains( params[:bigArrayType], "hdf5" )
        ba = H5sBigArray( inputs[:h5sDir] )
    elseif contains( params[:bigArrayType], "imagetile" )
        ba = ImageTileArray(inputs[:address], params[:port], params[:node])
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
        referenceChunk = fetch(c, inputs[:referenceChunk])
        origin      = referenceChunk.origin[1:N]
        chunkSize   = size(referenceChunk)[1:N]
        if length(origin) > N
            origin = origin[1:N]
            chunkSize = chunkSize[1:N]
        elseif length(origin) < N
            origin = [origin..., ones(typeof(origin), N-length(origin))...]
        end
    else
        origin = params[:origin]
        chunkSize = params[:chunkSize]
    end

    if haskey(params, :originOffset)
        origin .+= params[:originOffset]
    end

    # cutout as chunk
    data = ba[map((x,y)->x:x+y-1, origin, chunkSize)...]

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

    println("cout out chunk size: $(size(data))")

    # put chunk to channel for use
    put!(c, outputs[:data], chk)
end
