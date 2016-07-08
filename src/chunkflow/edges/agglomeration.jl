include("edge.jl")
using EMIRT
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
    # and segmentation with mst
    @assert isa(chk_sgm.data, Tsgm)
    @assert isa(chk_aff.data, Taff)

    # run watershed
    dend, dendValues = Process.forward(chk_aff.data, chk_sgm.data.seg)
    @show dend
    @show dendValues
    chk_sgm.data = Tsgm(chk_sgm.data.seg, dend, dendValues)
    #chk_sgm.data = sgm

    # put output to channel
    put!(c, e.outputs[1], chk_sgm)

    println("--------------agg end--------------")
end
