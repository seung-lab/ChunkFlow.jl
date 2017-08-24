VERSION >=v"0.5.0" && __precompile__(false)

module ChunkFlow

using DataStructures
using Agglomeration, Process
using BigArrays.Chunks
using AWSSDK.CloudWatch

include("core/dictchannel.jl")
include(joinpath(Pkg.dir(), "EMIRT/plugins/cloud.jl"))
include("core/task.jl")
include("nodes.jl")
include("core/error.jl")
include("core/argparser.jl")
include("utils/producer.jl")
include("utils/execute.jl")

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
            CloudWatch.put_metric_data(;Namespace="ChunkFlow/", 
                            MetricData=[["MetricName"   => "time_lapse",
                                         "Timestamp"    => now(),
                                         "Value"        => elapsed,
                                         "Unit"         => "Seconds",
                                         "Dimensions"   => [[
                                            "Name"      => "node",
                                            "Value"     => "$name"
                                        ]]
                            ]])
            info("--------end of $(name)-----------")
            println("--------end of $(name)-----------")
        end
    end 
    info("complete pipeline time cost: $((time()-pipeline_start)/60) min")
    println("-----------end pipeline----------------")
end

function forward(task::OrderedDict{Symbol, Any})
    return forward( Net(task) )
end

end # end of module ChunkFlow
