using ComputeFramework

abstract Tnode

type Tnode
    func::Function
    prms::Dict{ASCIIString, Any}
    inps::Dict{ASCIIString, Any}
    outs::Dict{ASCIIString, Any}
end

type Tnreader <: Tnode
