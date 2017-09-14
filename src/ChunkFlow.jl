VERSION >=v"0.5.0" && __precompile__(false)

module ChunkFlow

using DataStructures
using BigArrays.Chunks

include("utils/cloud.jl")
include("nodes.jl")
include("core/error.jl")
include("core/argparser.jl")
include("utils/producer.jl")
include("utils/execute.jl")
include("utils/watch.jl")

using .Nodes

import .Watch

export forward


"""
construct a net from computation graph config file.
currently, the net was composed by nodes/layers
all the nodes was stored and managed in a DictChannel.
"""
function forward( task::OrderedDict{Symbol, Any} )
    # the global dict channel 
    c = Dict()
    t = Watch.Timer()
    for (name, d) in task 
        info("----- start $(name) -----")
        node = eval(Symbol(d[:kind]))()
        Nodes.run(node, c, d)
        elapsed = Watch.get_elapsed!(t)
        Watch.record_elapsed(name, elapsed)
        info("---- $(name): $(elapsed) -----")
    end
    total_elapsed = Watch.get_total_elapsed(t)
    Watch.record_elapsed("TotalPipeline", total_elapsed)
    info("----------- total elapsed: $(total_elapsed) ------------")
end

end # end of module ChunkFlow
