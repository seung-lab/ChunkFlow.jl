include("../src/ChunkNet.jl")
using EMIRT
using DataStructures
using ChunkNet
using ChunkNet.Producer

# parse the arguments as a dictionary, key is string
global const argDict = parse_commandline()
@show argDict

# setup AWS SQS queue name
global const AWS_SQS_QUEUE_NAME = argDict["awssqs"]
include("../src/core/task.jl")

taskproducer( argDict )
