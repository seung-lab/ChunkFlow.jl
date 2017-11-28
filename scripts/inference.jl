using ChunkFlow
using GSDicts
using BigArrays
using BigArrays.Chunks
using AWSCore
using AWSSQS
using DataStructures

channels = Dict{String, Channel}()
channels["img"] = Channel{Chunk}(1)
channels["aff"] = Channel{Chunk}(1)

# build task channel
aws = AWSCore.aws_config()
queue = sqs_get_queue(aws, "chunkflow-inference")
for m in sqs_messages( queue )
    task = JSON.parse( m[:message], dicttype=OrderedDict{Symbol,Any} )
    @sync begin
        #cut out image chunk
        @async ChunkFlow.Nodes.run(NodeCutoutChunk(), channels, task[:input])
        # run inference 
        ChunkFlow.Nodes.run(NodeKaffe(), channels, task[:CPUInferenceUNet])
        # save chunk
        @async ChunkFlow.Nodes.run(NodeBlendChunk(), channels, task[:saveaff])
    end
    sqs_delete_message(q,m)
end



