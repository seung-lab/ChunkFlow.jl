using HDF5

include(joinpath(Pkg.dir(), "EMIRT/plugins/aws.jl"))
include("../../chunk/chunk.jl")

using DataStructures

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
        fname = download(awsEnv, fname, "/tmp/")
    end
    @show fname
    chk = readchk(fname)
    # put chunk to channel for use
    put!(c, outputs[:data], chk)

    # release memory
    chk = nothing
    gc()
end
