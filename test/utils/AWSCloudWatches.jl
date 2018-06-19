using Base.Test
using ChunkFlow.Utils.AWSCloudWatches

@testset "test cloud watch" begin
    AWSCloudWatches.record_elapsed("test-edge-name", 35)
end

