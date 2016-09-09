using HDF5
using BigArrays
using DataStructures

"""
edge function of readh5
"""
function ef_readchunk!(c::DictChannel,
                    params::OrderedDict{Symbol, Any},
                    inputs::OrderedDict{Symbol, Any},
                    outputs::OrderedDict{Symbol, Any} )
    fname = inputs[:fname]
    if iss3(fname)
        # download from s3
        fname = download(fname, "/tmp/")
    end
    @show fname
    chk = readchunk(fname)
    # put chunk to channel for use
    put!(c, outputs[:data], chk)

    # release memory
    chk = nothing
    gc()
end
