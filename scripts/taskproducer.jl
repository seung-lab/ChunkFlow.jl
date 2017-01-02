include("../src/ChunkFlow.jl")
using EMIRT
using DataStructures
using ChunkFlow
using ChunkFlow.Producer

# parse the arguments as a dictionary, key is string
global const argDict = parse_commandline()
@show argDict

taskproducer( argDict )
