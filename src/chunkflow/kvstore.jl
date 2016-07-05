abstract AbstractKVStore

type Tkvstore <: AbstractKVStore
    kv::Dict{Symbol, Any}
    # dependency number, when it is 0, delete the item
    # To-Do: dependency engine to analysis computation graph and get dependency number
    #dn::Dict{Symbol, Integer}
end

function Tkvstore()
    Tkvstore(Dict{Symbol,Any}())
end

function pull(s::Tkvstore, k::Symbol)
    Dict{Symbol, Any}(k => s[k])
end

function pull(s::Tkvstore, ks::Vector{Symbol})
    ret = Dict{Symbol, Any}()
    for k in ks
        ret[k] = s[k]
    end
    ret
end

function push!(s::Tkvstore, ins::Dict{Symbol, Any})
    for (k,v) in ins
        s[k] = v
    end
    s
end
