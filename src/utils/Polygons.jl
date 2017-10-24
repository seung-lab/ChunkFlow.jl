module Polygons

include(joinpath(Pkg.dir(), "ImageRegistration/src/geometry.jl"))

using DataStructures
export polygon_filter 

const DEFAUL_POLYGON = [10276 8116;
                        10276 43716;                                                                                 
                        65016 43716;                                                                                 
                        65016 4416;                                                                                  
                        10276 8116]
"""
    polygon_filter( originSet::Set{Vector}, polygon::Array{Int,2};
                            blockSize::NTuple{Int,2} = (512,512) )
only keep the origins, whose corresponding block is completely inside the polygon
"""
function polygon_filter(    originSet::OrderedSet{Vector};
                            polygon::Array{Int,2} = DEFAUL_POLYGON,
                            blockSize::Vector{Int} = [512,512] )
    @assert size(polygon, 2) == 2
    @assert polygon[1,:] == polygon[end, :]

    ret = Set{Vector}()
    for origin in originSet
        p1 = origin[1:2]
        p2 = [origin[1]                       (origin[2] + blockSize[2] -1)]
        p3 = [(origin[1] + blockSize[1] -1)   origin[2]]
        p4 = [(origin[1] + blockSize[1] -1)   (origin[2] + blockSize[2] -1)]
        #@show p1, p2, p3, p4
        #@show polygon
        if  pt_in_poly( p1, polygon ) && pt_in_poly( p2, polygon ) &&
            pt_in_poly( p3, polygon ) && pt_in_poly( p4, polygon )
            push!(ret, origin)
        else
            println("not inside polygon: $origin")
        end
    end
    
    return ret
end

end # module
