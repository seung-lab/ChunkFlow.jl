# include("../src/core/argparser.jl")
# include("../src/ChunkFlow.jl")
using Agglomeration, Process
@everywhere using Agglomeration, Process
@everywhere using ChunkFlow
@everywhere using ChunkFlow.Execute
@everywhere using Logging
@Logging.configure(level=DEBUG)
Logging.configure(filename="logfile.log")

# parse the arguments as a dictionary, key is string
@everywhere argDict = parse_commandline()
@show argDict

@sync begin
    for p in 1:nworkers()
        @async begin
            remotecall_wait(execute, p, argDict)
        end
    end
end

# @parallel for i in 1:nworkers()
#     execute( argDict )
# end
