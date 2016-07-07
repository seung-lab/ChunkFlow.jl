include("edge.jl")
using EMIRT
using Watershed
using DataStructures

export EdgeWatershed, forward!

type EdgeWatershed <: AbstractEdge
    kind::Symbol
    params::Dict{Symbol, Any}
    # the inputs and outputs are all nodes, which are in kvstore
    inputs::Vector{Symbol}
    outputs::Vector{Symbol}
end

function EdgeWatershed(conf::OrderedDict{UTF8String, Any})
    kind = Symbol(conf["kind"])
    @assert kind == :watershed
    params = Dict{Symbol, Any}()
    for (k,v) in conf["params"]
        params[Symbol(k)] = v
    end
    inputs = [Symbol(conf["inputs"][1])]
    @assert length(conf["inputs"]) == 1
    outputs = [Symbol(conf["outputs"][1])]
    @assert length(conf["outputs"]) == 1

    EdgeWatershed(kind, params, inputs, outputs)
end

function forward!( c::DictChannel, e::EdgeWatershed )
    chk = fetch(c, e.inputs[1])
    aff = chk.data
    # check it is an affinity map
    @assert isa(aff, Taff)

    # use percentage threshold
    e, count = hist(aff[:], 100000)
    low  = percent2thd(e, count, e.params[:low])
    high = percent2thd(e, count, e.params[:high])
    thds = Vector{Tuple}()
    for tp in e.params[:thresholds]
        push!(thds, tuple(tp[1], percent2thd(e, count, tp[2])))
    end
    dust = e.params[:dust]

    # watershed
    println("watershed...")
    seg, rg = watershed(aff, low, high, thds, dust)
    dend, dendValues = rt2dend(rg)
    chk.data = Tsgm( seg, dend, dendValues )

    put!(c, e.outputs[1], chk)
end
