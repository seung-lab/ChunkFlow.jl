VERSION >=v"0.4.0-dev+6521" && __precompile__()

module ChunkNet

using DataStructures
using Agglomeration
using Process

include("core/dictchannel.jl")
include(joinpath(Pkg.dir(), "EMIRT/plugins/cloud.jl"))
include("core/task.jl")
include("edges.jl")
include("core/error.jl")
include("core/argparser.jl")
include("utils/producer.jl")
include("utils/execute.jl")

export Net, forward

typealias Net OrderedDict{Symbol, Edge}

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
        @assert !haskey(net, ename)
        net[ename] = Edge(de)
    end
    net
end

function forward(net::Net)
    println("------------start pipeline------------")
    pipeline_start = time()
    c = DictChannel()
    for (name, e) in net
        # kind = string(e.kind)
        println("--------start $(name)-----------")
        info("--------start $(name)-----------")
        start = time()
        forward!(c, e)
        # force garbage collector to release memory
        gc()
        elapsed = time() - start
        info("time cost for $(name): $(elapsed/60) min")
        info("--------end of $(name)-----------")
    end
    info("complete pipeline time cost: $((time()-pipeline_start)/60) min")
    println("-----------end pipeline----------------")
end

function forward(task::OrderedDict{Symbol, Any})
    return forward( Net(task) )
end

end # end of module ChunkNet
