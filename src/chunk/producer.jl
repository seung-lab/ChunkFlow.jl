include("../bigarray/bigarray.jl")
include("chunk.jl")

typealias Tcoord Vector{Int}
typealias Tsz Vector{Int}

immutable Tchks
    ba::AbstractBigArray
    # where do we start in the bigarray
    origin::Tcoord
    # dimension of each chunk
    chksz::Tsz
    # overlap of each chunk
    overlap::Tsz
    # grid of chunks. let's say gridsz=(2,2,2), will produce 16 chunks
    gridsz::Tsz
    # voxel size
    voxelsize::Tsz
end

function Tchks(ba::AbstractBigArray, origin::Tcoord=[0,0,0],
                chksz::Tsz=[1024,1024,10], overlap::Tsz=[0,0,0],
                gridsz::Tsz=[1,1,1], voxelsize::Tsz=[1,1,1])
    Tchks(ba, origin, chksz, overlap, gridsz, voxelsize)
end
# iteration functions
# grid index as state, start from the first grid
Base.start(chks::Tchks) = Vector{UInt32}([1,1,1])
Base.done(chks::Tchks, grididx) = grididx[1]>chks.gridsz[1]

function Base.next(chks::Tchks, grididx::Vector)
    # get current chunk_
    step = chks.chksz .- chks.overlap
    start = chks.origin + (grididx-1) .* step
    stop = start + chks.chksz - 1
    arr = chks.ba[start[1]:stop[1], start[2]:stop[2], start[3]:stop[3]]
    chk = Chunk(arr, start, chks.voxelsize)

    # next grid index
    if grididx[1] < chks.gridsz[1]
        ngi = [grididx[1]+1, grididx[2], grididx[3]]
    elseif grididx[2] < chks.gridsz[2]
        ngi = [1, grididx[2]+1, grididx[3]]
    elseif grididx[3] < chks.gridsz[3]
        ngi = [1,1, grididx[3]+1]
    else
        ngi = grididx .+ [1,0,0]
    end
    return chk, ngi
end
