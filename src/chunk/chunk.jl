using EMIRT

abstract AbstractChunk

#include(joinpath(Pkg.dir(), "EMIRT/src/plugins/aws.jl"))

type Chunk <: AbstractChunk
    data::Union{Array, Tsgm}                  # could be 3-5 Dimension dataay
    origin::Vector     # measured by voxel number
    voxelsize::Vector  # physical size of each voxel
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
    Vector{UInt32}((chk.origin-1) .* chk.voxelsize)
end

function save(fname::AbstractString, chk::Chunk)
    if isfile(fname)
        rm(fname)
    end
    f = h5open(fname, "w")
    f["type"] = "chunk"
    if isa(chk.data, Array)
        f["data"] = chk.data
    elseif isa(chk.data, Tsgm)
        f["seg"] = chk.data.seg
        f["dend"] = chk.data.dend
        f["dendValues"] = chk.data.dendValues
    else
        error("not a standard chunk data structure")
    end
    f["origin"] = chk.origin
    f["voxelsize"] = chk.voxelsize
    close(f)
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