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

# pmap(execute, [argDict for i in 1:argDict[:workers]])

@sync begin
    for w in 1:argDict[:workernumber]
        @async begin
	    if argDict[:workernumber] > 1
            sleep((w-1)*argDict[:workerwaittime]*60)
	    end
            remotecall_wait(execute, w, argDict)
        end
    end
end

# for w in 2:argDict[:workers]
#     @spawn execute(argDict)
# end
# execute(argDict)
