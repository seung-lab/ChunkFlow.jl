include("edge.jl")
using EMIRT
using DataStructures

export EdgeExchangeAffXZ, forward!

type EdgeExchangeAffXZ <: AbstractEdge
    kind::Symbol
    params::Dict{Symbol, Any}
    # the inputs and outputs are all nodes, which are in kvstore
    inputs::Vector{Symbol}
    outputs::Vector{Symbol}
end

function EdgeExchangeAffXZ(conf::OrderedDict{UTF8String, Any})
    kind = Symbol(conf["kind"])
    @assert kind == :exchangeaffxz
    params = Dict{Symbol, Any}()
    for (k,v) in conf["params"]
        params[Symbol(k)] = v
    end
    inputs = [Symbol(conf["inputs"][1])]
    @assert length(conf["inputs"]) == 1
    outputs = [Symbol(conf["outputs"][1])]
    @assert length(conf["outputs"]) == 1

    EdgeExchangeAffXZ(kind, params, inputs, outputs)
end

function forward!( c::DictChannel, e::EdgeExchangeAffXZ)
    println("------------start exchange xz of affinity map ------------")
    chk = fetch(c, e.inputs[1])
    @assert isaff(chk.data)
    chk.data = exchangeaffxz!(chk.data)
    put!(c, e.outputs[1], chk)
    println("-----------exchange aff xz end---------------------")
end
