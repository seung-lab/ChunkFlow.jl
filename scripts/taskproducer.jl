using EMIRT
using DataStructures
include("../src/core/argparser.jl")

# parse the arguments as a dictionary, key is string
argDict = parse_commandline()
@show argDict

# setup AWS SQS queue name
global const sqsname = argDict["awssqs"]
include("../src/core/task.jl")

# read task config file
# produce task script
task = get_task( argDict["task"] )

# set gpu id
if !isa(argDict["gpuid"], Void)
  set_gpu_id!(task, argDict["gpuid"])
end

if iss3(task[:input][:inputs][:fileName])
    produce_tasks_s3img(task)
else
    produce_tasks_local(task)
end
