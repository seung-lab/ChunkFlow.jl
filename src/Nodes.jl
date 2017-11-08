module Nodes

using DataStructures

export AbstractNode, AbstractIONode, AbstractComputeNode, NodeConf

abstract type AbstractNode end
abstract type AbstractIONode <: AbstractNode end 
abstract type AbstractComputeNode <: AbstractNode end

# node configuration dictionary
const NodeConf = OrderedDict{Symbol, Any}

# define a function to inherite
function run end 

#include("nodes/agglomeration.jl")
#include("nodes/atomicseg.jl")
include("nodes/BlendChunk.jl"); using .BlendChunk; export NodeBlendChunk;
#include("nodes/Crop.jl"); using .Crop; export NodeCrop;
include("nodes/CutoutChunk.jl"); using .CutoutChunk; export NodeCutoutChunk;
#include("nodes/downsample.jl")
#include("nodes/hypersquare.jl")
include("nodes/Kaffe.jl"); using .Kaffe; export NodeKaffe;
#include("nodes/maskaffinity.jl")
#include("nodes/mergeseg.jl")
#include("nodes/movedata.jl")
#include("nodes/omni.jl")
#include("nodes/readchunk.jl")
include("nodes/ReadH5.jl"); using .ReadH5; export NodeReadH5;
#include("nodes/relabelseg.jl")
#include("nodes/remove.jl")
include("nodes/SaveChunk.jl"); using .SaveChunk; export NodeSaveChunk;
#include("nodes/savepng.jl")
include("nodes/Sleep.jl"); using .Sleep; export NodeSleep;
#include("nodes/watershed.jl")
#include("nodes/watershed_stage1.jl")
#include("nodes/znni.jl")

end # end of module 
