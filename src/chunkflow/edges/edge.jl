export AbstractEdge
abstract AbstractEdge

type Edge <: AbstractEdge
    kind::Symbol
    forward::Function
    params::OrderedDict{Symbol, Any}
    # the inputs and outputs are all nodes, which are in kvstore
    inputs::OrderedDict{Symbol, Any}
    outputs::OrderedDict{Symbol, Any}
end
include("readh5.jl")
include("crop.jl")
include("watershed.jl")
include("znni.jl")
include("agglomeration.jl")
include("omni.jl")
include("exchangeaffxz.jl")
"""
inputs:
ec: edge configuration dict
"""
function Edge( ec::OrderedDict{Symbol, Any} )
    kind = Symbol(ec[:kind])
    params = ec[:params]
    inputs = ec[:inputs]
    outputs = ec[:outputs]

    # function
    if ec[:kind] == "readh5"
        forward = ef_readh5!
    elseif ec[:kind] == "znni"
        forward = ef_znni!
    elseif ec[:kind] == "watershed"
        forward = ef_watershed!
    elseif ec[:kind] == "agglomeration"
        forward = ef_agglomeration!
    elseif ec[:kind] == "omnification"
        forward = ef_omnification
    elseif ec[:kind] == "crop"
        forward = ef_crop!
    elseif ec[:kind] == "exchangeaffxz"
        forward = ef_exchangeaffxz!
    else
        error("unsupported edge kind")
    end
    Edge(kind, forward, params, inputs, outputs)
end
