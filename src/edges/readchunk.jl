using HDF5
using BigArrays
using DataStructures

"""
edge function of readh5
"""
function nf_readchunk!(c::DictChannel,
                    params::OrderedDict{Symbol, Any},
                    inputs::OrderedDict{Symbol, Any},
                    outputs::OrderedDict{Symbol, Any} )
    # get file name
    if haskey(inputs, :fileName)
        fileName = inputs[:fileName]
    else
        @assert haskey(inputs, :prefix)
        start = params[:origin]
        stop  = start .+ params[:chunkSize] .-1
        fileName = "$(inputs[:prefix])$(start[1])-$(stop[1])_$(start[2])-$(stop[2])_$(start[3])-$(stop[3])$(inputs[:suffix])"
    end
    @show fileName

    if iss3(fileName)
        # download from s3
        fileName = download(fileName, "/tmp/")
    end
    @show fileName
    chk = readchunk(fileName)
    # put chunk to channel for use
    put!(c, outputs[:data], chk)

    rm(fileName)
end
