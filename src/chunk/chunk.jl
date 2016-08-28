using EMIRT
using HDF5

abstract AbstractChunk

#include(joinpath(Pkg.dir(), "EMIRT/plugins/aws.jl"))

type Chunk <: AbstractChunk
    data::Union{Array, Tsgm}                  # could be 3-5 Dimension dataay
    origin::Vector     # measured by voxel number
    voxelsize::Vector  # physical size of each voxel
end

function crop_border!{T}( chk::Chunk, cropsize::Union{Vector{T},Tuple{T}} )
    @assert typeof(chk.data) <: Array
    nd = ndims(chk.data)
    @assert nd >= 3
    sz = size(chk.data)
    @assert sz[1]>cropsize[1]*2 &&
            sz[2]>cropsize[2]*2 &&
            sz[3]>cropsize[3]*2
    if nd == 3
        chk.data = chk.data[cropsize[1]+1:sz[1]-cropsize[1],
                            cropsize[2]+1:sz[2]-cropsize[2],
                            cropsize[3]+1:sz[3]-cropsize[3]]
    elseif nd==4
        chk.data = chk.data[cropsize[1]+1:sz[1]-cropsize[1],
                            cropsize[2]+1:sz[2]-cropsize[2],
                            cropsize[3]+1:sz[3]-cropsize[3], :]
    elseif nd==5
        chk.data = chk.data[cropsize[1]+1:sz[1]-cropsize[1],
                            cropsize[2]+1:sz[2]-cropsize[2],
                            cropsize[3]+1:sz[3]-cropsize[3], :, :]
    else
        error("only support 3-5 D, current dataay dimention is $(nd)")
    end
    chk.origin += cropsize
    chk
end

function physical_offset( chk::Chunk )
    Vector{UInt32}((chk.origin-1) .* chk.voxelsize)
end

function save(fname::AbstractString, chk::Chunk)
    if isfile(fname)
        rm(fname)
    end
    f = h5open(fname, "w")
    f["type"] = "chunk"
    if isa(chk.data, Taff)
        # save with compression
        f["affinityMap", "chunk", (64,64,8,3), "shuffle", (), "deflate", 3] = chk.data
    elseif isa(chk.data, Timg) || isa(chk.data, Tseg)
        f["image", "chunk", (64,64,8), "shuffle", (), "deflate", 3] = chk.data
    elseif isa(chk.data, Tsgm)
        f["segmentation", "chunk", (64,64,8), "shuffle", (), "deflate", 3] = chk.data.seg
        f["segmentPair"] = chk.data.dend
        f["segmentAffinity"] = chk.data.dendValues
    else
        error("This is an unsupported type: $(typeof(chk.data))")
    end
    f["origin"] = Vector{UInt32}(chk.origin)
    f["voxelsize"] = Vector{UInt32}(chk.voxelsize)
    close(f)
end

function readchk(fname::AbstractString)
    f = h5open(fname)
    if has(f, "main")
        data = read(f["main"])
    elseif has(f, "affinityMap")
        data = read(f["affinityMap"])
    elseif has(f, "image")
        data = read(f, "image")
    elseif has(f, "segmentation")
        data = readsgm(fname)
    else
        error("not a standard chunk file")
    end
    origin = read(f["origin"])
    voxelsize = read(f["voxelsize"])
    close(f)
    return Chunk(data, origin, voxelsize)
end
