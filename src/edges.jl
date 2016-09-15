export AbstractEdge
abstract AbstractEdge

using DataStructures

type Edge <: AbstractEdge
    kind::Symbol
    forward::Function
    params::OrderedDict{Symbol, Any}
    # the inputs and outputs are all nodes, which are in kvstore
    inputs::OrderedDict{Symbol, Any}
    outputs::OrderedDict{Symbol, Any}
end

include(joinpath(Pkg.dir(), "EMIRT/plugins/cloud.jl"))


include("edges/agglomeration.jl")
include("edges/atomicseg.jl")
include("edges/blendchunk.jl")
include("edges/crop.jl")
include("edges/cutoutchunk.jl")
include("edges/hypersquare.jl")
include("edges/kaffe.jl")
include("edges/mergeseg.jl")
include("edges/movedata.jl")
include("edges/omni.jl")
include("edges/readchunk.jl")
include("edges/readh5.jl")
include("edges/relabelseg.jl")
include("edges/savechunk.jl")
include("edges/watershed.jl")
include("edges/znni.jl")

"""
library of edge function as a Dict
register a new function here for any new edge type
if the function name has a "!", the function will change the data in dictchannel
"""
const edgeFuncLib = Dict{Symbol, Function}(
  :agglomeration  => ef_agglomeration!,
  :atomicseg      => ef_atomicseg!,
  :blendchunk     => ef_blendchunk,
  :crop           => ef_crop!,
  :cutoutchunk    => ef_cutoutchunk!,
  :hypersquare    => ef_hypersquare,
  :kaffe          => ef_kaffe!,
  :mergeseg       => ef_mergeseg!,
  :movedata       => ef_movedata,
  :omnification   => ef_omnification,
  :readchunk      => ef_readchunk!,
  :readh5         => ef_readh5!,
  :relabelseg     => ef_relabelseg!,
  :savechunk      => ef_savechunk,
  :watershed      => ef_watershed!,
  :znni           => ef_znni!
)

"""
inputs:
ec: edge configuration dict
"""
function Edge( ec::OrderedDict{Symbol, Any} )
    kind = Symbol(ec[:kind])
    if kind==:bigarray || kind==:chunks
      return nothing
    else
      forward = edgeFuncLib[kind]
    end
    params = ec[:params]
    inputs = ec[:inputs]
    outputs = ec[:outputs]

    # function
    Edge(kind, forward, params, inputs, outputs)
end

function forward!(c::DictChannel, e::Edge)
    e.forward(c, e.params, e.inputs, e.outputs)
end
