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
        if k == "thresholds"
            tmpl = Vector{Dict{Symbol,Any}}()
            for d in v
                tmpd = Dict{Symbol,Any}()
                for (k2,v2) in d
                    tmpd[Symbol(k2)] = v2
                end
                push!(tmpl, tmpd)
            end
            v = tmpl
        end
        params[Symbol(k)] = v
    end
    inputs = [Symbol(conf["inputs"][1])]
    @assert length(conf["inputs"]) == 1
    outputs = [Symbol(conf["outputs"][1])]
    @assert length(conf["outputs"]) == 1

    EdgeWatershed(kind, params, inputs, outputs)
end

function forward!( c::DictChannel, e::EdgeWatershed )
    println("-----------start watershed------------")
    chk_aff = fetch(c, e.inputs[1])
    aff = chk_aff.data
    @show size(aff)
    # check it is an affinity map
    @assert isa(aff, Taff)

    # use percentage threshold
    b, count = hist(aff[:], 10000)
    low  = percent2thd(b, count, e.params[:low])
    high = percent2thd(b, count, e.params[:high])
    thds = Vector{Tuple}()
    for st in e.params[:thresholds]
        push!(thds, tuple(st[:size], percent2thd(b, count, st[:threshold])))
    end
    dust = e.params[:dust]

    # watershed
    println("watershed...")
    seg, rg = watershed(aff, low, high, thds, dust)
    dend, dendValues = rg2dend(rg)
    sgm = Tsgm( seg, dend, dendValues )

    # create chunk and put into channel
    chk_sgm = Chunk(sgm, chk_aff.origin, chk_aff.voxelsize)
    put!(c, e.outputs[1], chk_sgm)
    println("-----------watershed end--------------")
end
