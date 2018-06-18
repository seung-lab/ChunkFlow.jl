using BigArrays
using BigArrays.BinDicts
using BigArrays.S3Dicts
using BigArrays.GSDicts

using OffsetArrays
using AWSCore 
using AWSSQS
using ChunkFlow
using ChunkFlow.Edges.Kaffe
using ChunkFlow.Utils.AWSCloudWatches 
using ChunkFlow.Utils.ArgParsers
using JSON

if isfile("/secrets/aws-secret.json")
    d = JSON.parsefile("/secrets/aws-secret.json")
    for (k,v) in d
        ENV[k] = v
    end
end

const AWS_CREDENTIAL = AWSCore.aws_config()
const global ARG_DICT = parse_commandline()
const AWS_QUEUE = sqs_get_queue(AWS_CREDENTIAL, ARG_DICT[:queue-name])

const INPUT_LAYER = ARG_DICT[:input-layer]
const OUTPUT_LAYER = ARG_DICT[:output-layer]

if startswith(INPUT_LAYER, "s3://")
	const global baImg = BigArray(S3Dict(INPUT_LAYER))
elseif startswith(INPUT_LAYER, "gs://")
	const global baImg = BigArray(GSDict(INPUT_LAYER))
else 
	const global baImg = BigArray(BinDict(INPUT_LAYER))
end 

if startswith(OUTPUT_LAYER, "s3://")
	const global baAff = BigArray(S3Dict(OUTPUT_LAYER))
elseif startswith(INPUT_LAYER, "gs://")
	const global baAff = BigArray(GSDict(OUTPUT_LAYER))
else
	error("unsupported neuroglancer layer: $(OUTPUT_LAYER)")
end 

function read_image_worker(message)
    println("start read image worker...")
    startTime = time()
    pipelineLatencyStartTime = now()
    messageBody = message[:message]
    println("message body: ", messageBody)
   
    start = map(parse, split(messageBody, ","))                                                                                                
    cutoutRange = map((x,y)->x+1:x+y, start, ARG_DICT[:chunk-size])
    @show cutoutRange

    # cutout the chunk
    img = baImg[cutoutRange...]	
    
    elapsed = time() - startTime  
    AWSCloudWatches.record_elapsed("read_image_chunk", elapsed)
    println("elapse of read image submitted: ", elapsed)
    
    return pipelineLatencyStartTime, message, img 
end 

function convnet_inference_worker(pipelineLatencyStartTime, message, img)
    println("start inference worker...")
    startTime = time()
    patchStride = 1.0 - ARG_DICT[:patch-overlap]
    outArray = Kaffe.kaffe(img |> parent, ARG_DICT[:convnet-file];
        scanParams = "dict(stride=($(patchStride[3]),$(patchStride[2]),$(patchStride[1])),blend='bump')",
        caffeNetFile ="", caffeNetFileMD5 ="", 
        deviceID = ARG_DICT[:device-id], batchSize = 1,                               
        outputLayerName = "output")
    #outArray = Array{Float32, 4}(map(length, indices(img))..., 1)
    @assert size(outArray)[1:3] == size(img |> parent)
    @show size(outArray)
    
    marginCropSize = map((x,y)->div.(x-y,2), size(outArray)[1:3], ARG_DICT[:stride])
    @show marginCropSize
    
    @assert ndims(outArray) == 4
    sz = size(outArray)
    @show indices(img)
    newIndices = map( (x,y)->x.start+y:x.stop-y, 
                    (indices(img)..., 1:sz[4]), (marginCropSize..., 0))
    outArray = outArray[marginCropSize[1]+1 : sz[1]-marginCropSize[1],
                        marginCropSize[2]+1 : sz[2]-marginCropSize[2],
                        marginCropSize[3]+1 : sz[3]-marginCropSize[3], :]
    if sz[4]==1
        outArray = squeeze(outArray, 4)
        newIndices = newIndices[1:3]
    end 
    @show newIndices
    out = OffsetArray(outArray, newIndices...)

    elapsed = time() - startTime  
    AWSCloudWatches.record_elapsed("inference", elapsed)
    println("elapse of inference submitted: ", elapsed)

    return pipelineLatencyStartTime, message, out 
end 

function save_affinity_worker(pipelineLatencyStartTime, message, aff)
    println("start saving worker...")
    startTime = time()

    println("save affinitymap")
    merge(baAff, aff)
    #sleep(20)

    sqs_delete_message(AWS_QUEUE, message)
    
    elapsed = time() - startTime
    AWSCloudWatches.record_elapsed("save-affinitymap", elapsed)
    println("elapse of saving submitted: ", elapsed)	

    # the time stamp is using unit of Millisecond, need to transform to seconds
    AWSCloudWatches.record_elapsed("pipeline-latency", (now()-pipelineLatencyStartTime).value / 1000)
    nothing
end 

function main()
    for message in AWSSQS.sqs_messages(AWS_QUEUE)
        @show message
        if nothing==message break end 

        pipelineLatencyStartTime, message, img = read_image_worker(message)
        if all(img|>parent .== zero(eltype(img|>parent)))
            sqs_delete_message(AWS_QUEUE, message)
            continue
        end 
 
        pipelineLatencyStartTime, message, aff = convnet_inference_worker( pipelineLatencyStartTime, message, img )
        save_affinity_worker(pipelineLatencyStartTime, message, aff)
    end 
	println("all worker terminated, probably all done!")
end 

main()

