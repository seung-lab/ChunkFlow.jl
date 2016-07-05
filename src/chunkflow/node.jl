abstract AbstractNode <: Any

type Tnode <: AbstractNode
    kind::Symbol
    data::Tchunk
    depend_num::Integer
end
