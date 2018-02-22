include(joinpath(Pkg.dir("ChunkFlow"), "scripts/ArgParsers.jl")); using .ArgParsers;
include(joinpath(Pkg.dir("ChunkFlow"), "src/utils/AWSCloudWatches.jl")); using .AWSCloudWatches;
using BigArrays
using BigArrays.BinDicts
using BigArrays.S3Dicts
using BigArrays.GSDicts

using OffsetArrays
using AWSCore 
using AWSSQS
using ChunkFlow

const Image     = OffsetArray{UInt8,   3, Array{UInt8,3}}
const Affinity  = OffsetArray{Float32, 4, Array{Float32, 4}}

const AWS_CREDENTIAL = AWSCore.aws_config()
const global ARG_DICT = parse_commandline()
const AWS_QUEUE = sqs_get_queue(AWS_CREDENTIAL, ARG_DICT[:queuename])

const INPUT_LAYER = ARG_DICT[:inputlayer]
const OUTPUT_LAYER = ARG_DICT[:outputlayer]

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
    cutoutRange = map((x,y)->x+1:x+y, start, ARG_DICT[:chunksize])
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
    patchStride = 1.0 - ARG_DICT[:patchoverlap]
    outArray = ChunkFlow.Nodes.Kaffe.kaffe( img |> parent, ARG_DICT[:convnetfile];
        scanParams = "dict(stride=($(patchStride),$(patchStride),$(patchStride)),blend='bump')",
        caffeNetFile ="", caffeNetFileMD5 ="", 
        deviceID = ARG_DICT[:deviceid], batchSize = 1,                               
        outputLayerName = "output")
    @assert size(outArray)[1:3] == size(img |> parent)
    #outArray = Array{Float32, 4}(map(length, indices(img))..., 3)
    @show size(outArray)
    @show (ARG_DICT[:stride]..., size(outArray,4)) 
        marginCropSize = map((x,y)->div.(x-y,2), size(outArray), 
            (ARG_DICT[:stride]..., size(outArray,4)))
    @show marginCropSize
        newIndices = map( (x,y)->x.start+y:x.stop-y, 
                            (indices(img)..., 1:size(outArray,4)), marginCropSize)
    # crop
    sz = size(outArray)
    outArray = outArray[	marginCropSize[1]+1 : sz[1]-marginCropSize[1],
                marginCropSize[2]+1 : sz[2]-marginCropSize[2],
                marginCropSize[3]+1 : sz[3]-marginCropSize[3], :]
    @show newIndices
    out = OffsetArray(outArray, newIndices...)
    #sleep(30)

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

