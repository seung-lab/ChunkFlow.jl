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

include("readchk.jl")
include("savechk.jl")
include("readh5.jl")
include("crop.jl")
include("watershed.jl")
include("atomicseg.jl")
include("znni.jl")
include("agglomeration.jl")
include("omni.jl")
include("exchangeaffxz.jl")
include("movedata.jl")
include("kaffe.jl")

"""
library of edge function as a Dict
register a new function here for any new edge type
"""
const edgeFuncLib = Dict{Symbol, Function}(
  :readchk        => ef_readchk!,
  :readh5         => ef_readh5!,
  :savechk        => ef_savechk,
  :znni           => ef_znni,
  :watershed      => ef_watershed!,
  :atomicseg      => ef_atomicseg,
  :agglomeration  => ef_agglomeration,
  :omnification   => ef_omnification,
  :crop           => ef_crop,
  :movedata       => ef_movedata,
  :kaffe          => ef_kaffe!
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
