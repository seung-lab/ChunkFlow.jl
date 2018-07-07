module ReadH5
using ..Edges
using HDF5
using BigArrays
using BigArrays.Chunks
using DataStructures

include("../utils/Clouds.jl"); using .Clouds

export EdgeReadH5, run
struct EdgeReadH5 <: AbstractEdge end 

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
function Edges.run(x::EdgeReadH5, c::Dict{String, Channel},
                   nc::EdgeConf)
    params = nc[:params]
    inputs = nc[:inputs]
    outputs = nc[:outputs]
    fileName = inputs[:fileName]
    if Clouds.iss3(fileName)
        # download from s3
        fileName = Clouds.download(fileName, "/tmp/")
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
    outputKey = outputs[:data]
    if !haskey(c, outputKey)
        c[outputKey] = Channel{Chunk}(1)
    end 
    put!(c[outputKey], chk)

    # remove local file
    if params[:isRemoveSourceFile]
      rm(fileName)
    end
end

end # end of module
