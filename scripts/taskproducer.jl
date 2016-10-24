include("../src/ChunkNet.jl")
using EMIRT
using DataStructures
using ChunkNet

# parse the arguments as a dictionary, key is string
global const argDict = parse_commandline()
@show argDict

# setup AWS SQS queue name
global const AWS_SQS_QUEUE_NAME = argDict["awssqs"]
include("../src/core/task.jl")

task = get_task( argDict["task"] )
@show task

producer = get_task( argDict["producer"] )
# set gpu id
set!(task, :deviceID, argDict["deviceid"])


function process_task(gridIndex::Tuple)
    if producer != nothing
        # produce chunk
        try
            origin = argDict["origin"] .+ ([gridIndex...] .- 1) .* argDict["stride"]
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

function main()
    # read task config file
    # produce task script
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
        map(process_task, gridIndexList)
    else
        error("invalid input method: $(task[:input][:kind])")
    end
end

main()
