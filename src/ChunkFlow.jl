VERSION >=v"0.5.0" && __precompile__(false)

module ChunkFlow

using DataStructures
using Agglomeration, Process
using BigArrays.Chunks

include("core/dictchannel.jl")
include(joinpath(Pkg.dir(), "EMIRT/plugins/cloud.jl"))
include("core/task.jl")
include("nodes.jl")
include("core/error.jl")
include("core/argparser.jl")
include("utils/producer.jl")
include("utils/execute.jl")
include("utils/watch.jl")

import .Watch

export Net, forward

typealias Net OrderedDict{Symbol, Node}

"""
construct a net from computation graph config file.
currently, the net was composed by nodes/layers
all the nodes was stored and managed in a DictChannel.
"""
function Net( task::OrderedDict{Symbol, Any} )
    net = Net()

    # remove popchunk configuration
    delete!(task, :bigarray)
    delete!(task, :chunks)

    for (ename, de) in task
        @assert !haskey(net, ename)
        net[ename] = Node(de)
    end
    net
end

function forward(net::Net)
    println("------------start pipeline------------")
    pipeline_start = time()
    c = DictChannel()
    @sync begin 
        for (node_name, e) in net
            # kind = string(e.kind)
            println("--------start $(node_name)-----------")
            info("--------start $(node_name)-----------")
            start = time()
            forward!(c, e)
            # force garbage collector to release memory
            gc()
            elapsed = time() - start
            info("time cost for $(node_name): $(elapsed/60) min")
            Watch.record_elapsed(node_name, elapsed)
            info("--------end of $(node_name)-----------")
            println("--------end of $(node_name)-----------")
        end
    end 
    info("complete pipeline time cost: $((time()-pipeline_start)/60) min")
    println("-----------end pipeline----------------")
end

function forward(task::OrderedDict{Symbol, Any})
    return forward( Net(task) )
end

end # end of module ChunkFlow
