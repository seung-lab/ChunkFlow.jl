using HDF5

export AbstractEdge

abstract AbstractEdge <: Any

type Tedge <: AbstractEdge
    kind::Symbol
    func::Function
    params::Dict{Symbol, Any}
    # the inputs and outputs are all nodes, which are in kvstore
    inputs::Vector{Symbol}
    outputs::Vector{Symbol}
end

function Tedge( config::Dict{AbstractString, Any} )


function forward!(s::Tkvstore, e::Tedge)
    if e.kind == :read
        data = h5read(e.params[:fname],
                        e.params[:dname])
        @assert length(e.outputs) == 1
        ous = Dict{Symbol,Any}(e.outputs[1] => data)
    else
        # get values from store, returned a dictionary, key is the symbols
        ins = pull(s, e.inputs)
        # run the function, return a dictionary, key is a symbol
        ous = e.func(e.params, ins, e.outputs)
    end
    push!(s, ous)
end
