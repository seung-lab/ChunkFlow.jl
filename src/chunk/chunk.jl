using EMIRT
using HDF5

abstract AbstractChunk

#include(joinpath(Pkg.dir(), "EMIRT/plugins/cloud.jl"))

type Chunk <: AbstractChunk
    data::Union{Array, SegMST}                  # could be 3-5 Dimension dataay
    origin::Vector{UInt32}     # measured by voxel number
    voxelsize::Vector{UInt32}  # physical size of each voxel
end

"""
crop the 3D surrounding margin
"""
function crop_border{T}(chk::Chunk, cropMarginSize::Union{Vector{T},Tuple{T}})
  @assert typeof(chk.data) <: Array
  nd = ndims(chk.data)
  @assert nd >= 3
  sz = size(chk.data)
  @assert sz[1]>cropMarginSize[1]*2 &&
          sz[2]>cropMarginSize[2]*2 &&
          sz[3]>cropMarginSize[3]*2
  if nd == 3
      data = chk.data[cropMarginSize[1]+1:sz[1]-cropMarginSize[1],
                      cropMarginSize[2]+1:sz[2]-cropMarginSize[2],
                      cropMarginSize[3]+1:sz[3]-cropMarginSize[3]]
  elseif nd==4
      data = chk.data[cropMarginSize[1]+1:sz[1]-cropMarginSize[1],
                      cropMarginSize[2]+1:sz[2]-cropMarginSize[2],
                      cropMarginSize[3]+1:sz[3]-cropMarginSize[3], :]
  elseif nd==5
      data = chk.data[cropMarginSize[1]+1:sz[1]-cropMarginSize[1],
                      cropMarginSize[2]+1:sz[2]-cropMarginSize[2],
                      cropMarginSize[3]+1:sz[3]-cropMarginSize[3], :, :]
  else
      error("only support 3-5 D, current dataay dimention is $(nd)")
  end
  origin = chk.origin .+ cropMarginSize
  Chunk(data, origin, chk.voxelsize)
end

"""
compute the physical offset
"""
function physical_offset( chk::Chunk )
    Vector{UInt32}((chk.origin.-UInt32(1)) .* chk.voxelsize)
end

"""
save chunk in a hdf5 file
"""
function save(fname::AbstractString, chk::Chunk)
    if isfile(fname)
        rm(fname)
    end
    f = h5open(fname, "w")
    f["type"] = "chunk"
    if isa(chk.data, AffinityMap)
      # save with compression
      f["affinityMap", "chunk", (64,64,8,3), "shuffle", (), "deflate", 3] = chk.data
    elseif isa(chk.data, EMImage)
      f["image", "chunk", (64,64,8), "shuffle", (), "deflate", 3] = chk.data
    elseif isa(chk.data, Segmentation)
      f["segmentation", "chunk", (64,64,8), "shuffle", (), "deflate", 3] = chk.data
    elseif isa(chk.data, SegMST)
        f["segmentation", "chunk", (64,64,8), "shuffle", (), "deflate", 3] = chk.data.segmentation
        f["segmentPairs"] = chk.data.segmentPairs
        f["segmentPairAffinities"] = chk.data.segmentPairAffinities
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
    elseif has(f, "segmentPairs")
      data = readsgm(fname)
    elseif has(f, "segmentation")
        data = readseg(fname)
    else
        error("not a standard chunk file")
    end
    origin = read(f["origin"])
    voxelsize = read(f["voxelsize"])
    close(f)
    return Chunk(data, origin, voxelsize)
end
