VERSION >=v"0.6.0" && __precompile__(false)

module ChunkFlow
include("utils/include.jl"); using .Utils;
include("Errors.jl"); using .Errors;
include("edges/include.jl"); using .Edges 
include("ChunkFlowTasks.jl"); using .ChunkFlowTasks;
# include("DictChannels.jl"); using .DictChannels 

end # end of module ChunkFlow
