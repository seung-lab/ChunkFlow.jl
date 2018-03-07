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
const MASK_LAYER = ARG_DICT[:masklayer]

const MASK_SCALE = 2^4

if startswith(INPUT_LAYER, "s3://")
	const global baIn = BigArray(S3Dict(INPUT_LAYER))
elseif startswith(INPUT_LAYER, "gs://")
	const global baIn = BigArray(GSDict(INPUT_LAYER))
else 
	const global baIn = BigArray(BinDict(INPUT_LAYER))
end 

if startswith(MASK_LAYER, "s3://")
	const global baMask = BigArray(S3Dict(MASK_LAYER))
elseif startswith(MASK_LAYER, "gs://")
	const global baMask = BigArray(GSDict(MASK_LAYER))
else 
	const global baMask = BigArray(BinDict(MASK_LAYER))
end 



if startswith(OUTPUT_LAYER, "s3://")
	const global baOut = BigArray(S3Dict(OUTPUT_LAYER))
elseif startswith(INPUT_LAYER, "gs://")
	const global baOut = BigArray(GSDict(OUTPUT_LAYER))
else
	error("unsupported neuroglancer layer: $(OUTPUT_LAYER)")
end 

function read_worker(message)
    println("start read image worker...")
    startTime = time()
    pipelineLatencyStartTime = now()
    messageBody = message[:message]
    println("message body: ", messageBody)

    #cutoutRange = BigArrays.Indexes.string2unit_range( messageBody )
    start = map(parse, split(messageBody, ","))
    cutoutRange = map((x,y)->x+1:x+y, start, ARG_DICT[:stride])
    @show cutoutRange

    # cutout the chunk
    aff = baIn[cutoutRange..., 1:3]	
    
    elapsed = time() - startTime  
    AWSCloudWatches.record_elapsed("read_image_chunk", elapsed)
    println("elapse of read image submitted: ", elapsed)
    
    return pipelineLatencyStartTime, message, aff 
end 

function mask_affinitymap!(aff::OffsetArray)
    maskRange = [indices( aff )[1:3]...]
    maskRange[1] = div(maskRange[1].start-1, MASK_SCALE) : div(maskRange[1].stop, MASK_SCALE)
    maskRange[2] = div(maskRange[2].start-1, MASK_SCALE) : div(maskRange[2].stop, MASK_SCALE)
    maskRange[3] = maskRange[3].start-1 : maskRange[3].stop

    mask = baMask[maskRange[1:3]...]
    @unsafe for z in indices(aff, 3)
        @unsafe for y in indices(aff, 2)
            @unsafe for x in indices(aff, 1)
                if  !mask[div(x,MASK_SCALE), div(y,MASK_SCALE), z] || 
                    !mask[div(x,MASK_SCALE), div(y,MASK_SCALE), z-1]
                    aff[x,y,z,3] = zero(eltype(aff))
                end 
                if  !mask[div(x,MASK_SCALE), div(y,  MASK_SCALE), z] || 
                    !mask[div(x,MASK_SCALE), div(y-1,MASK_SCALE), z]
                    aff[x,y,z,2] = zero(eltype(aff))
                end 
                if  !mask[div(x,  MASK_SCALE), div(y,MASK_SCALE), z] || 
                    !mask[div(x-1,MASK_SCALE), div(y,MASK_SCALE), z]
                    aff[x,y,z,1] = zero(eltype(aff))
                end 
            end
        end
    end
    nothing
end 

function save_affinity_worker(pipelineLatencyStartTime, message, aff)
    println("start saving worker...")
    startTime = time()

    println("save affinitymap")
    merge(baOut, aff)

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

        pipelineLatencyStartTime, message, aff = read_worker(message)
        if all(aff|>parent .== zero(eltype(aff)))
            sqs_delete_message(AWS_QUEUE, message)
            continue
        end 
        
        mask_affinitymap!(aff) 
        save_affinity_worker(pipelineLatencyStartTime, message, aff)
    end 
	println("all worker terminated, probably all done!")
end 

main()

