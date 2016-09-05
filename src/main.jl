include("core/argparser.jl")
include("chunknet/ChunkNet.jl")
using ChunkNet
using Logging
@Logging.configure(level=DEBUG)
Logging.configure(filename="logfile.log")

# parse the arguments as a dictionary, key is string
argDict = parse_commandline()
@show argDict

global const sqsname = argDict["awssqs"]
include("aws/task.jl")

if !isa(argDict["task"], Void)
  # has local task definition
  task = get_task(argDict["task"])
  if !isa(argDict["gpuid"], Void)
    set_gpu_id!(task, argDict["gpuid"])
  end
  net = Net(task)
  forward(net)
else
  # fetch task from AWS SQS
  while true
    task, msg = get_task()

    # set the gpu device id to use
    if !isa(argDict["gpuid"], Void)
      set_gpu_id!(task, argDict["gpuid"])
    end
    @show task

    net = Net(task)
    forward(net)
    # delete task message in SQS
    deleteSQSmessage!(awsEnv, msg, sqsname)
    sleep(5)
  end
end
