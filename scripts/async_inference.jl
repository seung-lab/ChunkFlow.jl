include(joinpath(Pkg.dir("ChunkFlow"), "scripts/ArgParsers.jl")); using .ArgParsers;
include(joinpath(Pkg.dir("ChunkFlow"), "src/utils/AWSCloudWatches.jl")); using .AWSCloudWatches;
using BigArrays
using BigArrays.BinDicts
using S3Dicts
using GSDicts

using OffsetArrays
using AWSCore 
using AWSSQS
using ChunkFlow

const Image     = OffsetArray{UInt8,   3, Array{UInt8,3}}
const Affinity  = OffsetArray{Float32, 4, Array{Float32, 4}}

# timestamp, sqs queue handle, data
const imageChannel    = Channel{ Tuple{DateTime, Dict{Symbol,Any}, Image   }}(1)
const affinityChannel = Channel{ Tuple{DateTime, Dict{Symbol,Any}, Affinity}}(1)


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

function read_image_worker()
    println("start read image worker...")
    for message in AWSSQS.sqs_messages(AWS_QUEUE)
        @show message
        if nothing==message break end 
        startTime = time()
        pipelineLatencyStartTime = now()
        messageBody = message[:message]
        println("message body: ", messageBody)

        cutoutRange = BigArrays.Indexes.string2unit_range( messageBody )
        @show cutoutRange

        # cutout the chunk
        img = baImg[cutoutRange...]	
        if all(img|>parent .== zero(eltype(img|>parent)))
		    sqs_delete_message(AWS_QUEUE, message)
		    continue
	    end 
        #img = OffsetArray{UInt8}(cutoutRange...)
        #sleep(10)
         
        elapsed = time() - startTime  
        AWSCloudWatches.record_elapsed("read_image_chunk", elapsed)
        println("elapse of read image submitted: ", elapsed)
        
        println("put image to channel...")
        put!(imageChannel, (pipelineLatencyStartTime, message, img))
        #break
    end
    println("close image channel...")
    close(imageChannel)
    nothing
end 

function convnet_inference_worker()
    println("start inference worker...")
    for (pipelineLatencyStartTime, message, img) in imageChannel  
        startTime = time()
        outArray = ChunkFlow.Nodes.Kaffe.kaffe( img |> parent, ARG_DICT[:convnetfile];
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

        put!(affinityChannel, (pipelineLatencyStartTime, message, out))
	    #break
    end
    println("close affinity channel...") 
    close(affinityChannel)
    nothing
end 

function save_affinity_worker()
    println("start saving worker...")
    for (pipelineLatencyStartTime, message, aff) in affinityChannel
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
    end 
    nothing
end 

function main()
	@sync begin
        @async begin 
             while true 
                try 
                    read_image_worker()  
                catch err 
                    @show err
                    continue     
                end
            end 
        end 
        @async begin 
            while true 
                try 
                    convnet_inference_worker() 
                catch err 
                    @show err 
                    continue 
                end 
            end 
        end 
        @async begin 
            while true 
                try 
                    save_affinity_worker() 
                catch err 
                    @show err 
                    continue 
                end 
            end 
        end 
        #read_image_worker()  
        #convnet_inference_worker() 
        #save_affinity_worker() 
	end
	println("all worker terminated, probably all done!")
end 

main()

