module SaveChunk 
# save chunk from dictchannel to local disk or aws s3
using ..Nodes 
using BigArrays
using BigArrays.Chunks
using DataStructures
using ChunkFlow.Cloud

export NodeSaveChunk, run 
immutable NodeSaveChunk <: AbstractNode end 

"""
node function of readh5
"""
function Nodes.run(x::NodeSaveChunk, c::Dict,
                   nc::NodeConf)
    params = nc[:params]
    inputs = nc[:inputs]
    outputs = nc[:outputs]
    # get chunk
    chk = c[inputs[:chunk]]
    @async savechunk(chk, inputs, outputs)
end


function savechunk(chk::Chunk,
                    inputs::OrderedDict{Symbol, Any},
                    outputs::OrderedDict{Symbol, Any})
    origin = Chunks.get_origin(chk)
    voxelSize = chk
    if haskey(outputs, :chunkFileName)
        chunkFileName = outputs[:chunkFileName]
        @assert contains(chunkFileName, ".h5")
    else
        prefix = replace(outputs[:prefix],"~",homedir())
        chksz = size(chk)
        chunkFileName = "$(prefix)$(origin[1])-$(origin[1]+chksz[1]-1)_$(origin[2])-$(origin[2]+chksz[2]-1)_$(origin[3])-$(origin[3]+chksz[3]-1).$(inputs[:chunk]).h5"
    end
    if Cloud.iss3(chunkFileName)
        ftmp = string(tempname(), ".chk.h5")
        BigArrays.Chunks.save(ftmp, chk)
        Base.run(`aws s3 mv $ftmp $chunkFileName`)
    elseif ismatch(r"^gs://*", chunkFileName)
        ftmp = string(tempname(), ".chk.h5")
        BigArrays.Chunks.save(ftmp, chk)
        # GoogleCloud.Utils.Storage.upload(ftmp, chunkFileName)
        Base.run(`gsutil mv $ftmp $chunkFileName`)
    else
        BigArrays.Chunks.save(chunkFileName, chk)
    end
end
end # end of module
