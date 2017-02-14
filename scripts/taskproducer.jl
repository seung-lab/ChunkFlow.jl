include("../src/ChunkFlow.jl")
using EMIRT
using DataStructures
using ChunkFlow
using ChunkFlow.Producer

# parse the arguments as a dictionary, key is string
global const argDict = parse_commandline()
@show argDict

@repeat 4 try
    taskproducer( argDict )
catch err
    @show err, typeof(err)
end
