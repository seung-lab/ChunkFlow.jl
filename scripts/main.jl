# include("../src/core/argparser.jl")
# include("../src/ChunkFlow.jl")

# sleep a little and let the process fully launches
# https://github.com/JuliaLang/julia/issues/12381
@everywhere sleep(0.1)

import Agglomeration, Process; @everywhere using Agglomeration, Process
import ChunkFlow; @everywhere using ChunkFlow
import ChunkFlow.Execute; @everywhere using ChunkFlow.Execute
import Logging; @everywhere using Logging

@Logging.configure(level=INFO)
Logging.configure(filename="$(tempname()).log")

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

