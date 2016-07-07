include("dictchannel.jl")
include("edges/readh5.jl")
include("edges/crop.jl")
include("edges/watershed.jl")
include("edges/znni.jl")
include("edges/agglomeration.jl")
include("edges/omni.jl")
include("edges/exchangeaffxz.jl")

using DataStructures
export create_et, forward

typealias Net Vector{AbstractEdge}


"""
inputs:
ec: edge configuration dict
"""
function create_edge( ec::OrderedDict{UTF8String, Any} )
    if ec["kind"] == "readh5"
        return EdgeReadH5( ec )
    elseif ec["kind"] == "znni"
        return EdgeZNNi( ec )
    elseif ec["kind"] == "watershed"
        return EdgeWatershed( ec )
    elseif ec["kind"] == "agglomeration"
        return EdgeAgglomeration( ec )
    elseif ec["kind"] == "omnification"
        return EdgeOmni( ec )
    elseif ec["kind"] == "crop"
        return EdgeCrop( ec )
    elseif ec["kind"] == "exchangeaffxz"
        return EdgeExchangeAffXZ( ec )
    else
        error("unsupported edge kind")
    end
end


function create_net( dtask::OrderedDict{UTF8String, Any} )
    net = Net()
    for (ename, de) in dtask
        e = create_edge(de)
        push!(net, e)
    end
    net
end

function forward(net::Net)
    c = DictChannel()
    for e in net
        forward!(c, e)
    end
end
