using HDF5
using BigArrays
using BigArrays.H5sBigArrays
using BigArrays.AlignedBigArrays

"""
edge function of cutting out chunk from bigarray
"""
function ef_cutoutchunk!(c::DictChannel,
                    params::OrderedDict{Symbol, Any},
                    inputs::OrderedDict{Symbol, Any},
                    outputs::OrderedDict{Symbol, Any} )
    if contains( params[:bigArrayType], "align") || contains( params[:bigArrayType], "Align")
      @assert isfile( inputs[:registerFile] )
      ba = AlignedBigArray(inputs[:registerFile])
    elseif  contains( params[:bigArrayType], "H5" ) ||
            contains(params[:bigArrayType], "h5") ||
            contains( params[:bigArrayType], "hdf5" )
      ba = H5sBigArray( inputs[:h5sDir] )
    else
      error("invalid bigarray type: $(params[:bigArrayType])")
    end

    # get range
    if haskey(inputs, :referenceChunk)
        origin      = fetch(c, inputs[:referenceChunk]).origin
        chunkSize   = size(fetch(c, inputs[:referenceChunk]))[1:3]
    else
        origin = params[:origin]
        chunkSize = params[:chunkSize]
    end

    # cutout as chunk
    if ndims(ba)==3
      data = ba[origin[1] : origin[1]+chunkSize[1]-1,
                origin[2] : origin[2]+chunkSize[2]-1,
                origin[3] : origin[3]+chunkSize[3]-1]
    else
      @assert ndims(ba)==4
      data = ba[origin[1] : origin[1]+chunkSize[1]-1,
                origin[2] : origin[2]+chunkSize[2]-1,
                origin[3] : origin[3]+chunkSize[3]-1, :]
    end

    if haskey(params, :nonzeroRatioThreshold) &&
        countnz(data) / length(data) < params[:nonzeroRatioThreshold]
        warn("ratio of zeros $(countnz(data) / length(data)), over $(params[:nonzeroRatioThreshold]), origin: $(origin)")
        throw( ZeroOverFlowError() )
    end

    chk = Chunk(data, origin, params[:voxelSize])

    println("cout out chunk size: $(size(data))")

    # put chunk to channel for use
    put!(c, outputs[:data], chk)
end
