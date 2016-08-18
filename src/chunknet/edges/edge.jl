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

"""
inputs:
ec: edge configuration dict
"""
function Edge( ec::OrderedDict{Symbol, Any} )
    kind = Symbol(ec[:kind])
    if kind==:bigarray || kind==:chunks
        return nothing
    end
    params = ec[:params]
    inputs = ec[:inputs]
    outputs = ec[:outputs]

    # function
    if kind == :readchk
        forward = ef_readchk!
    elseif kind == :readh5
        forward = ef_readh5!
    elseif kind == :savechk
        forward = ef_savechk
    elseif kind == :znni
        forward = ef_znni!
    elseif kind == :watershed
        forward = ef_watershed!
    elseif kind == :atomicseg
        forward = ef_atomicseg
    elseif kind == :agglomeration
        forward = ef_agglomeration!
    elseif kind == :omnification
        forward = ef_omnification
    elseif kind == :crop
        forward = ef_crop!
    elseif kind == :exchangeaffxz
        forward = ef_exchangeaffxz!
    elseif kind == :movedata
        forward = ef_movedata
    else
        error("this kind of edge will not used for forward pass: $(ec[:kind])")
    end
    Edge(kind, forward, params, inputs, outputs)
end

function forward!(c::DictChannel, e::Edge)
    e.forward(c, e.params, e.inputs, e.outputs)
end
