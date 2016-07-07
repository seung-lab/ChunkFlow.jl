include("edge.jl")
using EMIRT
using DataStructures

export EdgeCrop, forward!

type EdgeCrop <: AbstractEdge
    kind::Symbol
    params::Dict{Symbol, Any}
    # the inputs and outputs are all nodes, which are in kvstore
    inputs::Vector{Symbol}
    outputs::Vector{Symbol}
end

function EdgeCrop(conf::OrderedDict{UTF8String, Any})
    kind = Symbol(conf["kind"])
    @assert kind == :crop
    params = Dict{Symbol, Any}()
    for (k,v) in conf["params"]
        params[Symbol(k)] = v
    end
    inputs = [Symbol(conf["inputs"][1])]
    @assert length(conf["inputs"]) == 1
    outputs = [Symbol(conf["outputs"][1])]
    @assert length(conf["outputs"]) == 1

    EdgeCrop(kind, params, inputs, outputs)
end

function forward!( c::DictChannel, e::EdgeCrop)
    println("-------start crop--------------")
    chk = fetch(c, e.inputs[1])
    chk.data = crop_border!(chk.data, e.params[:cropsize])
    put!(c, e.outputs[1], chk)
    println("-------crop end----------------")
end
