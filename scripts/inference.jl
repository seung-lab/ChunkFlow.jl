include("ArgParsers.jl"); using .ArgParsers;
include(joinpath(@__DIR__, "../src/utils/AWSCloudWatches.jl")); using .AWSCloudWatches;
using BigArrays
using OffsetArrays
using AWSCore 
using AWSSDK.SQS
using ChunkFlow

const Image     = OffsetArray{Array{UInt8,   3}, 3}
const Affinity  = OffsetArray{Array{Float32, 4}, 4}

# timestamp, sqs queue handle, data
const imageChannel    = Channel{ Tuple{DateTime, String, Image   }}(1)
const affinityChannel = Channel{ Tuple{DateTime, String, Affinity}}(1)


const AWS_CREDENTIAL = AWSCore.aws_config()
const global ARG_DICT = parse_commandline()
const QUEUE_URL = SQS.get_queue_url(AWS_CREDENTIAL, 
									QueueName=ARG_DICT[:awsqueue])["QueueUrl"]

const INPUT_LAYER = ARG_DICT[:inputlayer]
const OUTPUT_LAYER = ARG_DICT[:outputlayer]

if startwith(INPUT_LAYER, "s3://")
	const global baImg = BigArray(S3Dict(INPUT_LAYER))
elseif startwith(INPUT_LAYER, "gs://")
	const global baImg = BigArray(GSDict(INPUT_LAYER))
else 
	error("unsupported neuroglancer layer: $(INPUT_LAYER)")
end 

if startwith(OUTPUT_LAYER, "s3://")
	const global baAff = BigArray(S3Dict(OUTPUT_LAYER))
elseif startwith(INPUT_LAYER, "gs://")
	const global baAff = BigArray(GSDict(OUTPUT_LAYER))
else
	error("unsupported neuroglancer layer: $(OUTPUT_LAYER)")
end 

function read_image_worker()
    t = time()
	startTimeStamp = now()
    messages = SQS.receive_message(QueueUrl=QUEUE_URL)["messages"]
    @assert length(messages) == 1
    message = messages[1]
    receiptHandle = message["ReceiptHandle"]
	cutoutRange = BigArrays.Indexes.string2unit_range( message["Body"] )
    @show cutoutRange

    # cutout the chunk
	img = baImg[cutoutRange...]	
 
    elapse = time() - t 
	AWSCloudWatches.record_elapsed("read_image_chunk", elapsed)
    
	put!(imageChannel, (startTimeStamp, receiptHandle, img))
end 

function convnet_inference_worker()
	startTimeStamp, receiptHandle, img = take!(imageChannel)

	t = time()
	# run inference
	out = ChunkFlow.Nodes.Kaffe.kaffe( img |> parent, 
                caffeModelFile = ARG_DICT[:convnetfile];
                scanParams = scanParams, 
				preprocess = preprocess,  
				caffeNetFile ="", caffeNetFileMD5 ="", 
                deviceID = 0, batchSize = 1,                               
                outputLayerName = "output")
	

	elapsed = time() - t 
	AWSCloudWatches.record_elapsed("inference", elapsed)

	put!(affinityChannel, (startTimeStamp, receiptHandle, out))	
    nothing
end 

function save_affinity_worker()
    startTimeStamp, receiptHandle, aff = take!(affinityChannel)
	t = time()
    # save affinitymap
	merge(baAff, aff)
    SQS.delete_message(QueueUrl=queueUrl, ReceiptHandle=receiptHandle)
	
	elapsed = time() - t
	AWSCloudWatches.record_elapsed("save-affinitymap", elapsed)
    # the time stamp is using unit of Millisecond, need to transform to seconds
    AWSCloudWatches.record_elapsed("pipeline-latency", (now()-startTimeStamp).value / 1000)
end 

function main()
	@sync begin 
		@async read_image_worker()
		@async convnet_inference_worker()
		@async save_affinity_worker()
	end
	println("all worker terminated, probably all done!")
end 

main()

