module PZNet
using ..Edges 
using HDF5
using BigArrays
using EMIRT
using OffsetArrays
#using PyCall

using ChunkFlow.Utils.Clouds 

export EdgePZNet, run 
struct EdgePZNet <: AbstractComputeEdge end 

"""
edge function of pznet forward pass

{
    "params": {
        "outputLayerName": "output",
        "patchSize":    [20, 256, 256],
        "patchOverlap": [64,64,4],
        "cropMarginSize": [64,64,4,0],
        "outputLayerName": "output",
        "outputChannelNum": 3,
        "convnetPath": "/tmp/cores2",
    },
    "inputs":{
        "img": "img"
    },
    "outputs": {
        "out": "aff" 
    }
}
"""
function Edges.run(x::EdgePZNet, c::Dict{String, Channel},
                   edgeConf::EdgeConf)
    params = edgeConf[:params]
    inputs = edgeConf[:inputs]
    outputs = edgeConf[:outputs]
    # note that the fetch only use reference rather than copy
    # anychange for chk_img could affect the img in dickchannel
    chk_img = take!(c[inputs[:img]])

       
    local out::Array 
   
    # perform inference 
    #@pyimport chunkflow.block_inference_engine.BlockInferenceEngine as block_engine
	#@pyimport chunkflow.frameworks.pznet_patch_inference_engine.PZNetPatchInferenceEngine as patch_engine

	#patchEngine = patch_engine( params[:convnetPath] )
	#blockEngine = block_engine( 
	#	patch_inference_engine=patchEngine,
    #    patch_size=params[:patchSize],
    #    overlap=params[:patchOverlap],
	#	output_key=outputLayerName,
	#	output_channels=numOutputChannels)
    @show params[:patchSize]
    #out = blockEngine()
    out = pznet(chk_img |> parent, params[:convnetPath];
                patchSize = params[:patchSize],
                patchOverlap = params[:patchOverlap],
                outputLayerName = params[:outputLayerName],
                outputChannelNum = params[:outputChannelNum])
    # crop margin
    sz = size(out)
    cropMarginSize = params[:cropMarginSize]
    out = out[cropMarginSize[1]+1:sz[1]-cropMarginSize[1],
              cropMarginSize[2]+1:sz[2]-cropMarginSize[2],
              cropMarginSize[3]+1:sz[3]-cropMarginSize[3], :]


    imgOffset = indices( chk_img )
    outGlobalRange = map((i,o,s)->i.start+o:i.start+o+s-1, 
                         imgOffset, cropMarginSize, size(out))
    chk_out = OffsetArray(out, (outGlobalRange..., 1:size(out, 4)))
    
    outputChunkName = outputs[:chunk]
    if !haskey(c, outputChunkName)
        c[outputChunkName] = Channel{OffsetArray}(1)
    end 
    put!(c[outputChunkName], chk_out)
end 

function pznet( img::Array{UInt8, 3}, convnetPath::AbstractString; 
               patchSize::Union{Tuple,Vector} = (20, 256, 256),
               patchOverlap::Union{Vector, Tuple} = (4, 64, 64), 
               deviceID::Int = 0, 
               outputLayerName::AbstractString = "output",
               outputChannelNum = 3 )
    
    imageFile = "/tmp/image.h5"
    outputFile = "/tmp/output.h5"
    
    if isfile(imageFile)
        rm(imageFile)
    end
    if isfile(outputFile)
        rm(outputFile)
    end 

    h5write(imageFile, "main", img)

    # this is cpu inference setup 
    Base.run(`python3 /root/chunkflow/python/chunkflow/scripts/forward_pznet.py 
             -i $imageFile -o $outputFile -n $convnetPath 
             -p $(patchSize[3]) $(patchSize[2]) $(patchSize[1]) 
             -v $(patchOverlap[3]) $(patchOverlap[2]) $(patchOverlap[1]) 
             -l $outputLayerName 
             -c $outputChannelNum`)

    out = h5read(outputFile, "main")
    # remove temporary files
    rm(imageFile);  rm(outputFile);
    return out
end

"""
    download_net( netFileName::AbstractString )
download
"""
function download_net( fileName::AbstractString )
    # download trained network
    if isempty(fileName)
        return ""
    elseif Clouds.iss3(fileName) || Clouds.isgs(fileName)
        localFileName = replace(fileName, "gs://", "/tmp/")
        localFileName = replace(localFileName, "s3://", "/tmp/")
        localFileName = strip(localFileName, '/')
        localFileName = "/tmp/$(basename(localFileName))"
        @show localFileName
        if !isfile(localFileName) 
            Clouds.download(fileName, localFileName)
        end
    else
        localFileName = expanduser( fileName )
    end
    @assert (isdir(localFileName) || isfile(localFileName)) "convnet file not found: $(localFileName)"
    return localFileName
end

end # end of module
