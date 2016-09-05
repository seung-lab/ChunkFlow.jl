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

include("edges/readchk.jl")
include("edges/savechk.jl")
include("edges/readh5.jl")
include("edges/crop.jl")
include("edges/watershed.jl")
include("edges/atomicseg.jl")
include("edges/znni.jl")
include("edges/agglomeration.jl")
include("edges/omni.jl")
include("edges/movedata.jl")
include("edges/kaffe.jl")
include("edges/hypersquare.jl")
include("edges/mergeseg.jl")

"""
library of edge function as a Dict
register a new function here for any new edge type
"""
const edgeFuncLib = Dict{Symbol, Function}(
  :readchk        => ef_readchk!,
  :readh5         => ef_readh5!,
  :savechk        => ef_savechk,
  :znni           => ef_znni!,
  :watershed      => ef_watershed!,
  :atomicseg      => ef_atomicseg!,
  :agglomeration  => ef_agglomeration!,
  :omnification   => ef_omnification,
  :hypersquare    => ef_hypersquare,
  :crop           => ef_crop!,
  :movedata       => ef_movedata,
  :kaffe          => ef_kaffe!,
  :mergeseg       => ef_mergeseg!
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
