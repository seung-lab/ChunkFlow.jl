# type of bounding box
typealias Tbbox Tuple{UnitRange, UnitRange, UnitRange}

"""
get size of the bounding box
"""
function Base.size(bb::Tbbox)
    sz = Vector{Int}()
    for idx in bb
        push!(sz, length(idx))
    end
    (sz...)
end
