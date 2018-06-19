module Edges

import DataStructures: OrderedDict

export AbstractEdge, AbstractIOEdge, AbstractComputeEdge, EdgeConf

abstract type AbstractEdge end
abstract type AbstractIOEdge <: AbstractEdge end 
abstract type AbstractComputeEdge <: AbstractEdge end

# node configuration dictionary
const EdgeConf = OrderedDict{Symbol, Any}

# define a function to inherite
function run end 

#include("agglomeration.jl")
#include("atomicseg.jl")
include("savechunk.jl"); using .SaveChunk; export EdgeSaveChunk;
#include("Crop.jl"); using .Crop; export EdgeCrop;
include("cutoutchunk.jl"); using .CutoutChunk; export EdgeCutoutChunk;
#include("downsample.jl")
#include("hypersquare.jl")
#include("Kaffe.jl"); using .Kaffe; export EdgeKaffe;
#include("maskaffinity.jl")
#include("mergeseg.jl")
#include("movedata.jl")
#include("omni.jl")
#include("readchunk.jl")
#include("ReadH5.jl"); using .ReadH5; export EdgeReadH5;
#include("relabelseg.jl")
#include("remove.jl")
#include("SaveChunk.jl"); using .SaveChunk; export EdgeSaveChunk;
#include("savepng.jl")
include("Sleep.jl"); using .Sleep; export EdgeSleep;
#include("watershed.jl")
#include("watershed_stage1.jl")
#include("znni.jl")

end # end of module 
