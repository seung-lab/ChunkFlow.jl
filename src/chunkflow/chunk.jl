using EMIRT

abstract AbstractChunk

type Tchunk <: AbstractChunk
    arr::Array                  # could be 3-5 Dimension array
    offset::Vector{Integer}     # measured by voxel number
    voxelsize::Vector{Integer}  # physical size of each voxel
end

# default value
function Tchunk(arr::Array, offset::Vector{Integer}=[0,0,0], voxelsize::Vector{Integer}=[1,1,1])
    # currently only support 3D offset and voxelsize
    @assert length(offset) == 3
    @assert length(voxelsize) == 3
    Tchunk(arr, offset, voxelsize)
end

function crop_border( chk::Tchunk, cropsize::Union{Vector,Tuple} )
    nd = ndims(chk.arr)
    @assert nd >= 3
    sz = size(chk.arr)
    @assert sz[1]>cropsize[1]*2 &&
            sz[2]>cropsize[2]*2 &&
            sz[3]>cropsize[3]*2
    if nd == 3
        chk.arr = chk.arr[  cropsize[1]+1:sz[1]-cropsize[1],
                            cropsize[2]+1:sz[2]-cropsize[2],
                            cropsize[3]+1:sz[3]-cropsize[3]]
    elseif nd==4
        chk.arr = chk.arr[  cropsize[1]+1:sz[1]-cropsize[1],
                            cropsize[2]+1:sz[2]-cropsize[2],
                            cropsize[3]+1:sz[3]-cropsize[3], :]
    elseif nd==5
        chk.arr = chk.arr[  cropsize[1]+1:sz[1]-cropsize[1],
                            cropsize[2]+1:sz[2]-cropsize[2],
                            cropsize[3]+1:sz[3]-cropsize[3], :, :]
    else
        error("only support 3-5 D, current array dimention is $(nd)")
    end
    chk.offset -= cropsize
    chk
end

function physical_offset( chk::Tchunk )
    offset .* voxelsize
end

function save(fname::AbstractString, chk::Tchunk)
    h5write(fname, "type", "chunk")
    h5write(fname, "arr", chk.arr)
    h5write(fname, "offset", chk.offset)
    h5write(fname, "voxelsize", chk.voxelsize)
end

function readchk(fname::AbstractString)
    arr = h5read(fname, "arr")
    offset = h5read(fname, "offset")
    voxelsize = h5read(fname, "voxelsize")
    Tchunk(arr, offset, voxelsize)
end
