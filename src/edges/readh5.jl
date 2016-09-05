using HDF5

include(joinpath(Pkg.dir(), "EMIRT/plugins/aws.jl"))
include("../chunk/chunk.jl")

using DataStructures

"""
extract offset from file name
"""
function fname2offset(fname::AbstractString)
    # initialize the offset
    offset = Vector{Int64}()

    bn = basename(fname)
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
    fname = inputs[:fname]
    if iss3(fname)
        # download from s3
        fname = download(awsEnv, fname, "/tmp/")
    else
        fname = replace(fname, "~", homedir())
    end
    @show fname
    f = h5open(fname)
    arr = read(f[params[:datasetName]])
    origin = ones(UInt32, 3)
    if haskey(params, :origin) && params[:origin]!=[]
        origin = params[:origin]
    elseif has(f,"x_slice")
        origin[1] = h5read(fname, "x_slice")[1]
        origin[2] = h5read(fname, "y_slice")[1]
        origin[3] = h5read(fname, "z_slice")[1]
    else
        origin = fname2offset(fname)
    end
    close(f)
    voxelsize = params[:voxelsize]
    chk = Chunk(arr, origin, voxelsize)
    # put chunk to channel for use
    put!(c, outputs[:data], chk)

    chk = nothing
    gc()
end
