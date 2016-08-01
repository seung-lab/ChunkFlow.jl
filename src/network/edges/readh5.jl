using HDF5

include(joinpath(Pkg.dir(), "EMIRT/src/plugins/aws.jl"))
include("../../chunk/chunk.jl")

using DataStructures

export ef_readh5!

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
        env = build_env()
        fname = download(env, fname, "/tmp/")
    end
    @show fname
    arr = h5read(fname, params[:dname])
    origin = ones(UInt32, 3)

    if haskey(params, :origin) && params[:origin]!=[]
        origin = params[:origin]
    elseif has(f,"x_slice")
        f = h5open(fname)
        origin[1] = h5read(fname, "x_slice")[1]
        origin[2] = h5read(fname, "y_slice")[1]
        origin[3] = h5read(fname, "z_slice")[1]
        close(f)
    else
        origin = fname2offset(fname)
    end

    voxelsize = params[:voxelsize]
    chk = Chunk(arr, origin, voxelsize)
    # put chunk to channel for use
    put!(c, outputs[:data], chk)
end
