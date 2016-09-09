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
    fileName = inputs[:fileName]
    if iss3(fileName)
        # download from s3
        fileName = download(fileName, "/tmp/")
    end
    @show fileName
    chk = readchunk(fileName)
    # put chunk to channel for use
    put!(c, outputs[:data], chk)

    # release memory
    chk = nothing
    gc()
end
