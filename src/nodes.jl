export AbstractNode
abstract AbstractNode

using DataStructures

type Node <: AbstractNode
    kind::Symbol
    forward::Function
    params::OrderedDict{Symbol, Any}
    # the inputs and outputs are all nodes, which are in kvstore
    inputs::OrderedDict{Symbol, Any}
    outputs::OrderedDict{Symbol, Any}
end

include("nodes/agglomeration.jl")
include("nodes/atomicseg.jl")
include("nodes/blendchunk.jl")
include("nodes/crop.jl")
include("nodes/cutoutchunk.jl")
include("nodes/downsample.jl")
include("nodes/hypersquare.jl")
include("nodes/kaffe.jl")
include("nodes/maskaffinity.jl")
include("nodes/mergeseg.jl")
include("nodes/movedata.jl")
#include("nodes/omni.jl")
include("nodes/readchunk.jl")
include("nodes/readh5.jl")
include("nodes/relabelseg.jl")
include("nodes/remove.jl")
include("nodes/savechunk.jl")
include("nodes/savepng.jl")
include("nodes/sleep.jl")
include("nodes/watershed.jl")
#include("nodes/watershed_stage1.jl")
#include("nodes/znni.jl")

"""
library of node function as a Dict
register a new function here for any new node type
if the function name has a "!", the function will change the data in dictchannel
"""
const nodeFuncLib = Dict{Symbol, Function}(
  :agglomeration  => nf_agglomeration!,
  :atomicseg      => nf_atomicseg!,
  :blendchunk     => nf_blendchunk,
  :crop           => nf_crop!,
  :cutoutchunk    => nf_cutoutchunk!,
  :downsample     => nf_downsample,
  :hypersquare    => nf_hypersquare,
  :kaffe          => nf_kaffe!,
  :maskaffinity   => nf_maskaffinity!,
  :mergeseg       => nf_mergeseg!,
  :movedata       => nf_movedata,
#  :omnification   => nf_omnification,
  :readchunk      => nf_readchunk!,
  :readh5         => nf_readh5!,
  :relabelseg     => nf_relabelseg!,
  :remove         => nf_remove!,
  :savechunk      => nf_savechunk,
  :savepng        => nf_savepng,
  :sleep          => nf_sleep,
  :watershed      => nf_watershed!,
 # :watershed_stage1 => nf_watershed_stage1,
#  :znni           => nf_znni!
)

"""
inputs:
ec: node configuration dict
"""
function Node( ec::OrderedDict{Symbol, Any} )
    kind = Symbol(ec[:kind])
    if kind==:bigarray || kind==:chunks
      return nothing
    else
      forward = nodeFuncLib[kind]
    end
    params = ec[:params]
    inputs = ec[:inputs]
    outputs = ec[:outputs]

    # function
    Node(kind, forward, params, inputs, outputs)
end

function forward!(c::DictChannel, e::Node)
    e.forward(c, e.params, e.inputs, e.outputs)
end
