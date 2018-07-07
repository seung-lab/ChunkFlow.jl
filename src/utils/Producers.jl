module Producers

using ChunkFlow
using ChunkFlow.ChunkFlowTasks
using DataStructures
#using BigArrays.Utils
using AWSCore
using AWSSQS
using JSON
using BigArrays.S3Dicts 
using BigArrays.GSDicts


export submit_chunk_task, taskproducer, get_inputOffset_set

function get_input_offset_set( fileNameList::Vector )
    inputOffsetSet = Set()
    for fileName in fileNameList
        inputOffset = fileName2inputOffset( fileName; prefix = "block_" )
        push!(inputOffsetSet, inputOffset)
    end
    return inputOffsetSet
end

function get_input_offset_set(argDict::Dict)
    # cut out from a big array
    N = length(argDict[:gridsize])
    gridIndexList = Vector{Tuple}()
    inputOffsetSet = OrderedSet{Vector}()
    # the flag to indicate whether the specific inputOffset was visited
    if isempty(argDict[:continuefrom])
        flag = true
    else
        flag = false
    end
    for gridz in 1:argDict[:gridsize][3]
        for gridy in 1:argDict[:gridsize][2]
            for gridx in 1:argDict[:gridsize][1]
                if 3 < N
                    gridIndex = (gridx, gridy, gridz,
                                    ones(Int, N - 3)...)
                else
                    gridIndex = (gridx, gridy, gridz)
                end
                inputOffset = argDict[:inputoffset] .+ ([gridIndex...] .- 1) .* argDict[:outputblocksize]
                if inputOffset == argDict[:continuefrom]
                   flag = true
                end
                if flag
                    push!(inputOffsetSet, inputOffset)
                end
            end
        end
    end
    return inputOffsetSet
end

function taskproducer( argDict::Dict{Symbol, Any}; inputOffsetSet = Set{Vector}() )
    task = JSON.parsefile( argDict[:task], dicttype=OrderedDict{Symbol,Any} )
    # set gpu id
    if !isa(argDict[:deviceid], Void) 
        ChunkFlowTasks.set!(task, :deviceID, argDict[:deviceid])
    end 
    #@show task

    # the SQS queue 
    queuename = argDict[:queuename]
    if isempty(queuename)
        println("PRINT TASK JSONS (no queue has been set)")
    else
        aws = AWSCore.aws_config()
        queue = sqs_get_queue(aws, queuename)
    end
    # read task config file
    # produce task script
    if isempty( inputOffsetSet )
        inputOffsetSet = get_inputOffset_set( argDict )
    end

    for inputOffset in inputOffsetSet
        ChunkFlowTasks.set!(task, :inputOffset, inputOffset)
        if isempty(queuename)
            println(JSON.json(task))
        else
            println("offset of input chunk: $inputOffset")
            sqs_send_message(queue, JSON.json(task))
        end
    end
end

end # end of module
