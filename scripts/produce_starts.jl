using JSON
using AWSSDK.SQS
using BigArrays
using ChunkFlow.Utils.ArgParsers  

if isfile("/secrets/aws-secret.json")
    sec = JSON.parse_file("/secrets/aws-secret.json")
    for k,v in sec
        # setup environment variables for aws config 
        ENV[k] = v
    end 
end

const aws = AWSCore.aws_config()

global const ARG_DICT = parse_commandline()
@show ARG_DICT

const QUEUE_URL = SQS.get_queue_url(aws, QueueName=ARG_DICT[:queue-name])["QueueUrl"]
@show QUEUE_URL 
const GRID_SIZE = ARG_DICT[:grid-size]
const STRIDE = ARG_DICT[:stride]
const CHUNK_SIZE = ARG_DICT[:chunk-size]

outputStartList = Vector{NTuple{3,Int}}()
for z in 1:ARG_DICT[:grid-size][3]
    for y in 1:ARG_DICT[:grid-size][2]
        for x in 1:ARG_DICT[:grid-size][1]
            start = map((g,o,s) ->o+(g-1)*s, (x,y,z), ARG_DICT[:output-start], ARG_DICT[:stride])
            push!(outputStartList, (start...))
        end 
    end 
end 

println("get $(length(outputStartList)) starting points.")

if ARG_DICT[:is-shuffle]
    shuffle!(outputStartList)
end 


for i in 1:10:length(outputStartList)
    println("submitting start id: $(i) --> $(i+9)")
    # follow the neuroglancer 0-based python convention
    messageList = map(x->string(x[1]-1, ",", x[2]-1, ",", x[3]-1), 
                      outputStartList[i:min(i+9, length(outputStartList))])
    messageBatch = map((x,y)->["Id"=>string(i+x-1), "MessageBody"=>y],
                                    1:length(messageList), messageList)
    @show messageBatch
    SQS.send_message_batch(aws; QueueUrl=QUEUE_URL, 
                           SendMessageBatchRequestEntry=messageBatch)
end 

#for start in outputStartList
#    range = map((x,y)->x:x+y-1, start, ARG_DICT[:chunksize])  
#    message = BigArrays.Indexes.unit_range2string( [range...] )
#    @show message
#    SQS.send_message(aws; QueueUrl=QUEUE_URL, MessageBody=message)
#end 
