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
function Net( task::OrderedDict{Symbol, Any} )
    net = Net()

    # remove popchunk configuration
    delete!(task, :bigarray)
    delete!(task, :chunks)

    for (ename, de) in task
        e = Edge(de)
        if e!=nothing
            push!(net, e)
        end
    end
    net
end

function forward(net::Net)
    info("------------start pipeline------------")
    c = DictChannel()
    for e in net
        kind = string(e.kind)
        info("--------start $(kind)-----------")
        start = time()
        forward!(c, e)
        elapsed = time() - start
        info("-------------$(kind) end -------")
        info("time cost for $(kind): $(elapsed/60) min")
    end
    info("-----------end pipeline----------------")
end
