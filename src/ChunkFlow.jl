VERSION >=v"0.5.0" && __precompile__(false)

module ChunkFlow
include("Errors.jl"); using .Errors;
include("Nodes.jl"); using .Nodes
include("ChunkFlowTasks.jl"); using .ChunkFlowTasks;
# include("DictChannels.jl"); using .DictChannels 
#include("utils/Clouds.jl"); using .Clouds 

end # end of module ChunkFlow
