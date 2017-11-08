module Crop
using ..Nodes 
using DataStructures
export NodeCrop, run


struct NodeCrop <: AbstractNode end 

function Nodes.run( x::NodeCrop, c::AbstractChannel,
                   nodeConf::NodeConf)
    params = nodeConf[:params]
    inputs = nodeConf[:inputs]
    outputs = nodeConf[:outputs]
    for (k,v) in inputs
        @assert haskey(outputs, k)
        c[outputs[k]] = BigArrays.Chunks.crop_border(c[v], params[:cropMarginSize])
    end
end

end # end of module
