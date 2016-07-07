using HDF5

include("edge.jl")
include(joinpath(Pkg.dir(), "EMIRT/src/plugins/aws.jl"))
include("../chunk.jl")

using DataStructures

export EdgeReadH5, forward!

type EdgeReadH5 <: AbstractEdge
    kind::Symbol
    params::Dict{Symbol, Any}
    # the inputs and outputs are all nodes, which are in kvstore
    outputs::Vector{Symbol}
end

function EdgeReadH5(conf::OrderedDict{UTF8String, Any})
    kind = Symbol(conf["kind"])
    @assert kind == :readh5
    params = Dict{Symbol, Any}()
    for (k,v) in conf["params"]
        params[Symbol(k)] = v
    end
    outputs = [Symbol(conf["outputs"][1])]
    @assert length(conf["outputs"]) == 1

    EdgeReadH5(kind, params, outputs)
end

function forward!( c::DictChannel, e::EdgeReadH5 )
    fname = e.params[:fname]
    if iss3(fname)
        # download from s3
        env = build_env()
        fname = download(env, fname, "/tmp/")
    end
    @show fname
    arr = h5read(fname, e.params[:dname])
    origin = ones(UInt32, 3)
    f = h5open(fname)
    if has(f,"x_slice")
        origin[1] = h5read(fname, "x_slice")[1]
        origin[2] = h5read(fname, "y_slice")[1]
        origin[3] = h5read(fname, "z_slice")[1]
    end
    close(f)
    voxelsize = e.params[:voxelsize]
    chk = Chunk(arr, origin, voxelsize)
    # put chunk to channel for use
    put!(c, e.outputs[1], chk)
end
