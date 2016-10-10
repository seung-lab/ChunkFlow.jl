@everywhere include("../src/ChunkNet.jl")
@everywhere using EMIRT
@everywhere using DataStructures
@everywhere using ChunkNet

# parse the arguments as a dictionary, key is string
global const argDict = parse_commandline()
@show argDict

# setup AWS SQS queue name
global const AWS_SQS_QUEUE_NAME = argDict["awssqs"]
include("../src/core/task.jl")


@everywhere function process_task(task::ChunkFlowTask, producer::ChunkFlowTask, origin::Vector{Int})
    if producer != nothing
        # produce chunk
        try
            set!(producer, :origin, origin)
            forward( Net(producer) )
        catch err
            if isa( err, ZeroOverFlowError )
                return
            else
                rethrow()
            end
        end
    end
    # submit the corr
    set!(task, :origin, origin)
    submit(task)
end

function process_tasks(task::ChunkFlowTask, producer::ChunkFlowTask, gridIndexList::Vector)
    # gc_enable(false)
    @parallel for gridIndex in gridIndexList
        origin = argDict["origin"] .+ ([gridIndex...] .- 1) .* argDict["stride"]
        process_task(task, producer, origin)
    end
    # gc_enable(true)
end

function main()
    # read task config file
    # produce task script
    task = get_task( argDict["task"] )
    @show task

    producer = get_task( argDict["producer"] )
    # set gpu id
    set!(task, :deviceID, argDict["deviceid"])

    if contains(task[:input][:kind], "readh5")
        # tasks = ChunkFlowTaskList()
        tasks = produce_tasks(task)
        submit(tasks)
    elseif  contains(task[:input][:kind], "cutoutchunk") ||
            contains(task[:input][:kind], "readchunk")
        # cut out from a big
        gridIndexList = Vector{Tuple}()
        for gridz in 1:argDict["gridsize"][3]
            for gridy in 1:argDict["gridsize"][2]
                for gridx in 1:argDict["gridsize"][1]
                    push!(gridIndexList, (gridx, gridy, gridz))
                end
            end
        end
        process_tasks(task, producer, gridIndexList)
    else
        error("invalid input method: $(task[:input][:kind])")
    end
end

main()
