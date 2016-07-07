import JSON
import DataStructures

include("network.jl")

ftask = ARGS[1]

task = readall(ftask)
dtask = JSON.parse(task, dicttype=DataStructures.OrderedDict)

@show dtask
net = create_net(dtask)

forward(net)
