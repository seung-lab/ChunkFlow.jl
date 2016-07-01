abstract Tnode

type Tnode
    func::Function
    prms::Dict{Symbol, Any}
    inps::Dict{Symbol, Any}
    outs::Dict{Symbol, Any}
end

type Tnreader <: Tnode
