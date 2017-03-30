# include("../src/core/argparser.jl")
# include("../src/ChunkFlow.jl")
using Agglomeration, Process
@everywhere using Agglomeration, Process
@everywhere using ChunkFlow
@everywhere using ChunkFlow.Execute
@everywhere using Logging
#@everywhere using Retry

@Logging.configure(level=DEBUG)
Logging.configure(filename="logfile.log")

# parse the arguments as a dictionary, key is string
@everywhere argDict = parse_commandline()
@show argDict

asyncmap(execute, [argDict for i in 1:argDict[:workers]])
