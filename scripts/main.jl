include(joinpath(@__DIR__, "ArgParsers.jl"))
using ArgParsers 

# sleep a little and let the process fully launches
# https://github.com/JuliaLang/julia/issues/12381
@everywhere sleep(1)

#import Agglomeration, Process; @everywhere using Agglomeration, Process
import ChunkFlow; @everywhere using ChunkFlow
import ChunkFlow.ChunkFlowTasks; @everywhere using ChunkFlow.ChunkFlowTasks

#logging(open("$(tempname()).log", "w"))

# parse the arguments as a dictionary, key is string
@everywhere argDict = parse_commandline()
@show argDict

# pmap(execute, [argDict for i in 1:argDict[:workers]])

# support for multiple processing, so we can choose a number of parallel processes 
@sync begin
    for workerId in 1:argDict[:workernumber]
        @async begin
            if argDict[:workernumber] > 1
                sleep( (workerId-1) * argDict[:workerwaittime]*60 )
            end
            remotecall_wait(execute, workerId, argDict)
        end
    end
end

