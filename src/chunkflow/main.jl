using JSON
using DataStructures

include("network.jl")

ftask = ARGS[1]

task = readall(ftask)
dtask = JSON.parse(task, dicttype=OrderedDict{Symbol, Any})

@show dtask
net = Net(dtask)

forward(net)
