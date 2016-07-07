using EMIRT

abstract AbstractChunk

type Chunk <: AbstractChunk
    data::Union{Array, Tsgm}                  # could be 3-5 Dimension array
    origin::Vector{Integer}     # measured by voxel number
    voxelsize::Vector{Integer}  # physical size of each voxel
end

function crop_border( chk::Chunk, cropsize::Union{Vector,Tuple} )
    @assert typeof(chk.data) <: Array
    nd = ndims(chk.data)
    @assert nd >= 3
    sz = size(chk.data)
    @assert sz[1]>cropsize[1]*2 &&
            sz[2]>cropsize[2]*2 &&
            sz[3]>cropsize[3]*2
    if nd == 3
        chk.data = chk.data[  cropsize[1]+1:sz[1]-cropsize[1],
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
    chk.origin -= cropsize
    chk
end

function physical_offset( chk::Chunk )
    (chk.origin-1) .* voxelsize
end

function save(fname::AbstractString, chk::Chunk)
    h5write(fname, "type", "chunk")
    h5write(fname, "arr", chk.arr)
    h5write(fname, "origin", chk.origin)
    h5write(fname, "voxelsize", chk.voxelsize)
end

function readchk(fname::AbstractString)
    arr = h5read(fname, "arr")
    origin = h5read(fname, "origin")
    voxelsize = h5read(fname, "voxelsize")
    Chunk(arr, origin, voxelsize)
end
