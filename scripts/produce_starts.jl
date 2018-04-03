using AWSSDK.SQS
using BigArrays
using ChunkFlow.Utils.ArgParsers  

const aws = AWSCore.aws_config()

global const ARG_DICT = parse_commandline()
@show ARG_DICT

const QUEUE_URL = SQS.get_queue_url(aws, QueueName=ARG_DICT[:queuename])["QueueUrl"]
@show QUEUE_URL 
const GRID_SIZE = ARG_DICT[:gridsize]
const STRIDE = ARG_DICT[:stride]
const CHUNK_SIZE = ARG_DICT[:chunksize]

startList = Vector{NTuple{3,Int}}()
for z in 1:ARG_DICT[:gridsize][3]
    for y in 1:ARG_DICT[:gridsize][2]
        for x in 1:ARG_DICT[:gridsize][1]
            start = map((g,o,s) ->o+(g-1)*s, (x,y,z), ARG_DICT[:origin], ARG_DICT[:stride])
            push!(startList, (start...))
        end 
    end 
end 

println("get $(length(startList)) starting points.")

if ARG_DICT[:isshuffle]
    shuffle!(startList)
end 


for i in 1:10:length(startList)
    println("submitting start id: $(i) --> $(i+9)")
    # follow the neuroglancer 0-based python convention
    messageList = map(x->string(x[1]-1, ",", x[2]-1, ",", x[3]-1), 
                      startList[i:min(i+9, length(startList))])
    messageBatch = map((x,y)->["Id"=>string(i+x-1), "MessageBody"=>y],
                                    1:length(messageList), messageList)
    @show messageBatch
    SQS.send_message_batch(aws; QueueUrl=QUEUE_URL, 
                           SendMessageBatchRequestEntry=messageBatch)
end 

#for start in startList
#    range = map((x,y)->x:x+y-1, start, ARG_DICT[:chunksize])  
#    message = BigArrays.Indexes.unit_range2string( [range...] )
#    @show message
#    SQS.send_message(aws; QueueUrl=QUEUE_URL, MessageBody=message)
#end 
