module Nodes

using DataStructures

export AbstractNode, NodeConf

abstract AbstractNode
# node configuration dictionary
typealias NodeConf OrderedDict{Symbol, Any}

# define a function to inherite
export run
function run end 

#include("nodes/agglomeration.jl")
#include("nodes/atomicseg.jl")
include("nodes/blendchunk.jl"); using .BlendChunk; export NodeBlendChunk;
include("nodes/crop.jl"); using .Crop; export NodeCrop;
include("nodes/cutoutchunk.jl"); using .CutoutChunk; export NodeCutoutChunk;
#include("nodes/downsample.jl")
#include("nodes/hypersquare.jl")
include("nodes/kaffe.jl"); using .Kaffe; export NodeKaffe;
#include("nodes/maskaffinity.jl")
#include("nodes/mergeseg.jl")
#include("nodes/movedata.jl")
#include("nodes/omni.jl")
#include("nodes/readchunk.jl")
#include("nodes/readh5.jl")
#include("nodes/relabelseg.jl")
#include("nodes/remove.jl")
#include("nodes/savechunk.jl")
#include("nodes/savepng.jl")
include("nodes/sleep.jl"); using .Sleep; export NodeSleep;
#include("nodes/watershed.jl")
#include("nodes/watershed_stage1.jl")
#include("nodes/znni.jl")


end # end of module 
