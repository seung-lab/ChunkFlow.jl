VERSION >=v"0.5.0" && __precompile__(false)

module ChunkFlow

using DataStructures
using BigArrays.Chunks

include("Nodes.jl"); using .Nodes
include("Errors.jl"); using .Errors;
include("ChunkFlowTasks.jl"); using .ChunkFlowTasks;
include("DictChannels.jl"); using .DictChannels 
include("utils/AWSCloudWatches.jl"); using .AWSCloudWatches
include("utils/Clouds.jl"); using .Clouds 

export forward

"""
construct a net from computation graph config file.
currently, the net was composed by nodes/layers
all the nodes was stored and managed in a DictChannel.
"""
function forward( task::OrderedDict{Symbol, Any} )
    # the global dict channel 
    c = DictChannel()
    t = AWSCloudWatches.Timer()
    for (name, d) in task 
        AWSCloudWatches.info("----- start $(name) -----")
        node = eval(Symbol(d[:kind]))()
        Nodes.run(node, c, d)
        elapsed = AWSCloudWatches.get_elapsed!(t)
        AWSCloudWatches.record_elapsed(name, elapsed)
        AWSCloudWatches.info("---- elapse of $(name): $(elapsed) -----")
    end
    total_elapsed = AWSCloudWatches.get_total_elapsed(t)
    AWSCloudWatches.record_elapsed("TotalPipeline", total_elapsed)
    AWSCloudWatches.info("------ total elapsed of pipeline: $(total_elapsed) --------")
end

end # end of module ChunkFlow
