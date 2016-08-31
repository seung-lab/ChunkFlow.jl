include("aws/task.jl")
include("chunknet/ChunkNet.jl")

using Logging
@Logging.configure(level=DEBUG)
Logging.configure(filename="logfile.log")

using ChunkNet

if length(ARGS) >0
    task = get_task(ARGS[1])
    net = Net(task)
    forward(net)
else
    while true
        task, msg = get_task()

        @show task

        net = Net(task)
        forward(net)
        # delete task message in SQS
        deleteSQSmessage!(env, msg, sqsname)
        sleep(5)
    end
end
