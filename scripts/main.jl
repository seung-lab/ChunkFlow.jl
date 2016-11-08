# include("../src/core/argparser.jl")
include("../src/ChunkNet.jl")
using ChunkNet
using ChunkNet.Execute
using Logging
@Logging.configure(level=DEBUG)
Logging.configure(filename="logfile.log")

# parse the arguments as a dictionary, key is string
argDict = parse_commandline()
@show argDict

global const AWS_SQS_QUEUE_NAME = argDict["awssqs"]
include("../src/core/task.jl")

execute( argDict )
