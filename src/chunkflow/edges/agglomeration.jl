include("edge.jl")
using Agglomeration
using Process
using DataStructures

export EdgeAgglomeration, forward!

type EdgeAgglomeration <: AbstractEdge
    kind::Symbol
    params::Dict{Symbol, Any}
    # the inputs and outputs are all nodes, which are in kvstore
    inputs::Vector{Symbol}
    outputs::Vector{Symbol}
end

function EdgeAgglomeration(conf::OrderedDict{UTF8String, Any})
    kind = Symbol(conf["kind"])
    @assert kind == :agglomeration
    params = Dict{Symbol, Any}()
    for (k,v) in conf["params"]
        params[Symbol(k)] = v
    end
    inputs = [Symbol(conf["inputs"][1]), Symbol(conf["inputs"][2])]
    @assert length(conf["inputs"]) == 2
    outputs = [Symbol(conf["outputs"][1])]
    @assert length(conf["outputs"]) == 1

    EdgeAgglomeration(kind, params, inputs, outputs)
end

function forward!( c::DictChannel, e::EdgeAgglomeration )
    println("------------start agg-----------------")
    chk_sgm = fetch(c, e.inputs[1])
    chk_aff = fetch(c, e.inputs[2])

    # check it is an affinity map
    @assert isaff(chk_aff.data)
    @assert issgm(chk_sgm.data)

    # run watershed
    chk_sgm.data = watershed(chk.data)
    dend, dendValues = Process.forward(chk_aff.data, chk_sgm.data.seg)
    chk_sgm.data = Tsgm(chk_sgm.data.seg, dend, dendValues)

    # put output to channel
    put!(c, e.outputs[1], chk_sgm)

    println("--------------agg end--------------")
end
