using EMIRT

abstract AbstractChunk

type Chunk <: AbstractChunk
    data::Union{Array, Tsgm}                  # could be 3-5 Dimension dataay
    origin::Vector{Integer}     # measured by voxel number
    voxelsize::Vector{Integer}  # physical size of each voxel
end

function crop_border!( chk::Chunk, cropsize::Union{Vector,Tuple} )
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
        chk.data = chk.data[  cropsize[1]+1:sz[1]-cropsize[1],
                            cropsize[2]+1:sz[2]-cropsize[2],
                            cropsize[3]+1:sz[3]-cropsize[3], :]
    elseif nd==5
        chk.data = chk.data[  cropsize[1]+1:sz[1]-cropsize[1],
                            cropsize[2]+1:sz[2]-cropsize[2],
                            cropsize[3]+1:sz[3]-cropsize[3], :, :]
    else
        error("only support 3-5 D, current dataay dimention is $(nd)")
    end
    chk.origin += cropsize
    chk
end

function physical_offset( chk::Chunk )
    (chk.origin-1) .* chk.voxelsize
end

function save(fname::AbstractString, chk::Chunk)
    h5write(fname, "type", "chunk")
    if isa(chk.data, Array)
        h5write(fname, "data", chk.data)
    elseif isa(chk.data, Tsgm)
        savesgm(fname, chk.data)
    else
        error("not a standard chunk data structure")
    end
    h5write(fname, "origin", chk.origin)
    h5write(fname, "voxelsize", chk.voxelsize)
end

function readchk(fname::AbstractString)
    f = h5open(fname)
    if has(f, "data")
        data = h5read(fname, "data")
    elseif has(f, "seg")
        data = readsgm(fname)
    else
        error("not a standard chunk file")
    end
    origin = h5read(fname, "origin")
    voxelsize = h5read(fname, "voxelsize")
    Chunk(data, origin, voxelsize)
end
