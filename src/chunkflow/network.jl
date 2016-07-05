typealias Tnet Vector{Tedge}

function Tnet( dc::Dict{AbstractString, Dict{AbstractString, Any}} )
    ret = Tnet()
    for (ename, de) in dc
        e = Tedge(de)
    end
end

function forward(net::Tnet)
    nodes = Tkvstore()
    for e in net
        forward!(e, nodes)
    end
end
