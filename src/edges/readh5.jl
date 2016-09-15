using HDF5
using BigArrays
using DataStructures

"""
extract offset from file name
"""
function filename2offset(fileName::AbstractString)
    # initialize the offset
    offset = Vector{Int64}()

    bn = basename(fileName)
    name, ext = splitext(bn)
    # substring list
    strlst = split(name, "_")
    for str in strlst
        if contains(str, "-")
            strlst2 = split(str, "-")
            if typeof(parse(strlst2[1]))<:Int64
                push!(offset, parse(strlst2[1]))
            end
        end
    end
    if length(offset)==3
        return offset
    else
        warn("invalid auto offset, use default [0,0,0]!")
        return Vector{UInt32}([0,0,0])
    end
end

"""
edge function of readh5
"""
function ef_readh5!(c::DictChannel,
                    params::OrderedDict{Symbol, Any},
                    inputs::OrderedDict{Symbol, Any},
                    outputs::OrderedDict{Symbol, Any} )
    fileName = inputs[:fileName]
    if iss3(fileName)
        # download from s3
        fileName = download(fileName, "/tmp/")
    else
        fileName = replace(fileName, "~", homedir())
    end
    @show fileName
    f = h5open(fileName)
    arr = read(f[params[:datasetName]])
    origin = ones(UInt32, 3)
    if haskey(params, :origin) && params[:origin]!=[]
        origin = params[:origin]
    elseif has(f,"x_slice")
        origin[1] = h5read(fileName, "x_slice")[1]
        origin[2] = h5read(fileName, "y_slice")[1]
        origin[3] = h5read(fileName, "z_slice")[1]
    else
        origin = filename2offset(fileName) + 1
    end
    close(f)
    voxelSize = params[:voxelSize]
    chk = Chunk(arr, origin, voxelSize)
    # put chunk to channel for use
    put!(c, outputs[:data], chk)

    # remove local file
    if params[:isRemoveSourceFile]
      rm(fileName)
    end
end
