include("aws/task.jl")
include("core/argparser.jl")
include("chunknet/ChunkNet.jl")

using Logging
@Logging.configure(level=DEBUG)
Logging.configure(filename="logfile.log")

using ChunkNet

# parse the arguments as a dictionary, key is string
argDict = parse_commandline()
@show argDict

if haskey(argDict, "task")
  # has local task definition
  task = get_task(argDict["task"])
  if haskey(argDict, "gpuid")
    set_gpu_id!(task, argDict["gpuid"])
  end
  net = Net(task)
  forward(net)
else
  # fetch task from AWS SQS
  while true
    task, msg = get_task()

    # set the gpu device id to use
    if haskey(argDict, "gpuid")
      set_gpu_id!(task, argDict["gpuid"])
    end
    @show task

    net = Net(task)
    forward(net)
    # delete task message in SQS
    deleteSQSmessage!(env, msg, sqsname)
    sleep(5)
  end
end
