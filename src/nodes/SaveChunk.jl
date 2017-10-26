module SaveChunk 
# save chunk from dictchannel to local disk or aws s3
using ..Nodes 
using BigArrays
using BigArrays.Chunks
using DataStructures

include("../DictChannels.jl"); using .DictChannels
include("../utils/Clouds.jl"); using .Clouds

export NodeSaveChunk, run 
immutable NodeSaveChunk <: AbstractNode end 

"""
node function of readh5
"""
function Nodes.run(x::NodeSaveChunk, c::Dict{String, Channel},
                   nc::NodeConf)
    params = nc[:params]
    inputs = nc[:inputs]
    outputs = nc[:outputs]
    # get chunk
    chk = take!(c[inputs[:chunk]])
    
    if haskey(params, :chunkFileName)
        chunkFileName = params[:chunkFileName]
        @assert contains(chunkFileName, ".h5")
    else
        prefix = replace(params[:prefix],"~",homedir())
        chksz = size(chk)
        chunkFileName = "$(prefix)$(origin[1])-$(origin[1]+chksz[1]-1)_$(origin[2])-$(origin[2]+chksz[2]-1)_$(origin[3])-$(origin[3]+chksz[3]-1).$(inputs[:chunk]).h5"
    end

    @async savechunk(chk, chunkFileName)
end


function savechunk(chk::Chunk, chunkFileName::String)
    origin = Chunks.get_origin(chk)
    voxelSize = chk
    if Clouds.iss3(chunkFileName)
        ftmp = string(tempname(), ".chk.h5")
        BigArrays.Chunks.save(ftmp, chk)
        Base.run(`aws s3 mv $ftmp $chunkFileName`)
    elseif ismatch(r"^gs://*", chunkFileName)
        ftmp = string(tempname(), ".chk.h5")
        BigArrays.Chunks.save(ftmp, chk)
        # GoogleCloud.Utils.Storage.upload(ftmp, chunkFileName)
        # actually gsutil can also handle aws s3 file, 
        # no need to distinguish them. not tested, so keep this style
        Base.run(`gsutil mv $ftmp $chunkFileName`)
    else
        BigArrays.Chunks.save(chunkFileName, chk)
    end
end
end # end of module
