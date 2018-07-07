module Crop
using ..Edges 
using DataStructures
export EdgeCrop, run


struct EdgeCrop <: AbstractEdge end 

function Edges.run( x::EdgeCrop, c::AbstractChannel,
                   edgeConf::EdgeConf)
    params = edgeConf[:params]
    inputs = edgeConf[:inputs]
    outputs = edgeConf[:outputs]
    for (k,v) in inputs
        @assert haskey(outputs, k)
        c[outputs[k]] = BigArrays.Chunks.crop_border(c[v], params[:cropMarginSize])
    end
end

end # end of module
