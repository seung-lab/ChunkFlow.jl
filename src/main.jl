include("aws/task.jl")
include("network/network.jl")

using Logging
@Logging.configure(level=INFO)
Logging.configure(filename="logfile.log")



while true
    task = get_task()

    @show task

    net = Net(task)
    forward(net)

    if length(ARGS)>0
        # only one specific task
        break 
    end
    sleep(5)

end
