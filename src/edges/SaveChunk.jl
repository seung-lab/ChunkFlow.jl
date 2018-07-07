module SaveChunk

# save chunk from dictchannel to BigArrays
using ..Edges 
using BigArrays
#using H5sBigArrays
using BigArrays.GSDicts
using BigArrays.S3Dicts
using BigArrays.BinDicts 
using DataStructures
#using BOSSArrays
#using CloudVolume

export EdgeSaveChunk, run

struct EdgeSaveChunk <: AbstractIOEdge end 

"""
edge function of blendchunk
"""
function Edges.run(x::EdgeSaveChunk, c::Dict{String, Channel},
                   edgeConf::EdgeConf)
    params = edgeConf[:params]
    inputs = edgeConf[:inputs]
    # get chunk
    chk = take!(c[inputs[:chunk]])
    @show size(chk|>parent)

 #   if contains(params[:backend], "h5s")
  #      ba = H5sBigArray(expanduser(outputs[:bigArrayDir]);)
    if ismatch(r"^gs://*", params[:outputPath])
        d = GSDict( params[:outputPath] )
        ba = BigArray(d)
    elseif ismatch(r"^s3://*", params[:outputPath])
        d = S3Dict( params[:outputPath] )
        ba = BigArray(d)
    elseif isdir(params[:outputPath])
        d = BinDict( params[:outputPath] )
        ba = BigArray(d) 
   # elseif contains(params[:backend], "boss")
   #     ba = BOSSArray(
   #             T               = eval(Symbol(params[:dataType])),
   #             N               = params[:dimension],
   #             collectionName  = params[:collectionName],
   #             experimentName  = params[:experimentName],
   #             channelName     = params[:channelName],
   #             resolutionLevel = params[:resolutionLevel])
    #elseif contains(params[:backend], "olume")
    #    ba = CloudVolumeWarpper( params[:outputPath]; is1based=true )
    else
        error("unsupported bigarray backend: $(params[:backend])")
    end
    # save the chunk to bigarray 
    merge(ba, chk)
end

end # end of module
