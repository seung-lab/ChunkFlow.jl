using HDF5

include(joinpath(Pkg.dir(), "EMIRT/src/plugins/aws.jl"))
include("../chunk.jl")

using DataStructures

export ef_readh5!

"""
edge function of readh5
"""
function ef_readh5!( c::DictChannel, e::Edge )
    @assert e.kind == :readh5
    fname = e.inputs[:fname]
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
    put!(c, e.outputs[:img], chk)
end
