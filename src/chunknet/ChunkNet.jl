VERSION >=v"0.4.0-dev+6521" && __precompile__()

module ChunkNet

using DataStructures

include("dictchannel.jl")
include("edges.jl")

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
    println("------------start pipeline------------")
    c = DictChannel()
    for e in net
        kind = string(e.kind)
        println("--------start $(kind)-----------")
        info("--------start $(kind)-----------")
        start = time()
        forward!(c, e)
        # force garbage collector to release memory
        gc()
        elapsed = time() - start
        info("time cost for $(kind): $(elapsed/60) min")
    end
    println("-----------end pipeline----------------")
end

end
