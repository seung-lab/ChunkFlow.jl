include("aws/task.jl")
include("network/network.jl")

using Logging
@Logging.configure(level=INFO)
Logging.configure(filename="logfile.log")

if length(ARGS) >0
    task = get_task(ARGS[1])
    net = Net(task)
    forward(net)
else
    while true
        task = get_task()

        @show task

        net = Net(task)
        forward(net)
        sleep(5)
    end
end
