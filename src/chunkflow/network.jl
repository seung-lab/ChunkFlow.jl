include("dictchannel.jl")
include("edges/edge.jl")

using DataStructures
export Net, forward

typealias Net Vector{Edge}

"""
construct a net from computation graph config file.
currently, the net was composed by edges/layers
all the nodes was stored and managed in a DictChannel.
"""
function Net( dtask::OrderedDict{Symbol, Any} )
    net = Net()
    for (ename, de) in dtask
        e = Edge(de)
        push!(net, e)
    end
    net
end

function forward(net::Net)
    c = DictChannel()
    for e in net
        forward!(c, e)
    end
end
