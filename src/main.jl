include("aws/task.jl")
include("network/network.jl")

task = get_task()

@show task

net = Net(task)
forward(net)
