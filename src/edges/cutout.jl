using HDF5
using BigArrays
using BigArrays.H5sBigArrays
using BigArrays.AlignedBigArrays

"""
edge function of cutting out chunk from bigarray
"""
function ef_cutout(c::DictChannel,
                    params::OrderedDict{Symbol, Any},
                    inputs::OrderedDict{Symbol, Any},
                    outputs::OrderedDict{Symbol, Any} )
    if contains( params[:bigArrayType], "align") || contains( params[:bigArrayType], "Align")
      @assert isfile( inputs[:registerFile] )
      ba = AlignedBigArray(inputs[:registerFile])
    elseif  contains( params[:bigArrayType], "H5" ) ||
            contains(params[:bigArrayType], "h5") ||
            contains( params[:bigArrayType], "hdf5" )
      ba = H5sBigArray( inputs[:h5sDir];
                        blockSize = params[:blockSize],
                        chunkSize = params[:chunkSize] )
    else
      error("invalid bigarray type: $(params[:bigArrayType])")
    end

    # get range
    origin = params[:origin]
    size = params[:size]
    # cutout as chunk
    data = ba[rx, ry, rz]

    chk = Chunk(data, origin, params[:voxelSize])

    # put chunk to channel for use
    put!(c, outputs[:data], chk)
end
