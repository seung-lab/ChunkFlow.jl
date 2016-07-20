using HDF5

include(joinpath(Pkg.dir(), "EMIRT/src/plugins/aws.jl"))
include("../../chunk/chunk.jl")

using DataStructures

export ef_readchk!

"""
edge function of readh5
"""
function ef_readchk!(c::DictChannel,
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
    chk = readchk(fname)
    # put chunk to channel for use
    put!(c, outputs[:data], chk)
end