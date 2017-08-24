
"""
    auto_delete!(task::ChunkFlowTask)

auto matically delete the chunk in dictchannel, if they were not used in future node functions.

"""
function auto_delete!(task::ChunkFlowTask)
