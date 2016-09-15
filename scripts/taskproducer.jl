using EMIRT
using DataStructures
include("../src/core/argparser.jl")

# parse the arguments as a dictionary, key is string
argDict = parse_commandline()
@show argDict

# setup AWS SQS queue name
global const AWS_SQS_QUEUE_NAME = argDict["awssqs"]
include("../src/core/task.jl")

# read task config file
# produce task script
task = get_task( argDict["task"] )
@show task

# set gpu id
if !isa(argDict["gpuid"], Void)
    set!(task, :GPUID, argDict["gpuid"])
end

tasks = ChunkFlowTaskList()
if contains(task[:input][:kind], "readh5")
    tasks = produce_tasks(task)
elseif contains(task[:input][:kind], "cutoutchunk")
    for gridz in 1:argDict["gridsize"][3]
        for gridy in 1:argDict["gridsize"][2]
            for gridx in 1:argDict["gridsize"][1]
                gridIndex = [gridx, gridy, gridz]
                origin = argDict["origin"].+1 .+ (gridIndex .- 1) .* argDict["stride"]
                set!(task, :origin, origin)
                push!(tasks, task)
            end
        end
    end
else
    error("invalid input method: $(task[:input][:kind])")
end

submit(tasks)