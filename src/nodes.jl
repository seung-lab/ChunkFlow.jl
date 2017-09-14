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
#include("nodes/blendchunk.jl")
#include("nodes/crop.jl")
#include("nodes/cutoutchunk.jl")
#include("nodes/downsample.jl")
#include("nodes/hypersquare.jl")
#include("nodes/kaffe.jl")
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
include("nodes/sleep.jl")
#include("nodes/watershed.jl")
#include("nodes/watershed_stage1.jl")
#include("nodes/znni.jl")

using .Sleep 
export NodeSleep 

end # end of module 
