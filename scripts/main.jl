include("../src/core/argparser.jl")
include("../src/ChunkNet.jl")
using ChunkNet
using Logging
@Logging.configure(level=DEBUG)
Logging.configure(filename="logfile.log")

# parse the arguments as a dictionary, key is string
argDict = parse_commandline()
@show argDict

global const AWS_SQS_QUEUE_NAME = argDict["awssqs"]
include("../src/core/task.jl")

if argDict["task"]==nothing || isa(argDict["task"], Void)
    # fetch task from AWS SQS
    while true
        task, msg = get_task()

        # set the gpu device id to use
        if !isa(argDict["deviceid"], Void)
            set!(task, :deviceID, argDict["deviceid"])
        end
        @show task

        net = Net(task)
        forward(net)
        # delete task message in SQS
        deleteSQSmessage!(msg, AWS_SQS_QUEUE_NAME)
        sleep(5)
    end
else
    # has local task definition
    task = get_task(argDict["task"])
    if !isa(argDict["deviceid"], Void)
        set!(task, :deviceID, argDict["deviceid"])
    end
    net = Net(task)
    forward(net)
end
