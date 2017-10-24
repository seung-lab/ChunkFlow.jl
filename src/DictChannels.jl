module DictChannels

export DictChannel

type DictChannel <: AbstractChannel
    d::Dict
    cond_take::Condition    # waiting for data to become available
    DictChannel() = new(Dict(), Condition())
end

function Base.put!(D::DictChannel, k, v)
    D.d[k] = v
    notify(D.cond_take)
    D
end

function Base.setindex!(self::DictChannel, value::Any, key::String)
    put!(self, key, value)
end 

function Base.take!(D::DictChannel, k)
    v=fetch(D,k)
    delete!(D.d, k)
    v
end


function Base.haskey(self::DictChannel, key::AbstractString)
    haskey(self.d, key)
end 
Base.isready(D::DictChannel) = length(D.d) > 1
Base.isready(D::DictChannel, k) = haskey(D,k)
function Base.fetch(D::DictChannel, k)
    wait(D,k)
    D.d[k]
end

function Base.getindex( self::DictChannel, key::String )
    fetch(self, key)
end 

function Base.wait(D::DictChannel, k)
    while !isready(D, k)
        wait(D.cond_take)
    end
end

end # module
