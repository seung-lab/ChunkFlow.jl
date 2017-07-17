module Producer

#include(joinpath(dirname(@__FILE__), "polygon.jl"))

using ..ChunkFlow
using DataStructures
using BigArrays.Utils
using SQSChannels
using JSON
using S3Dicts

#const IS_USE_POLYGON_FILTER = false 
const IS_FILTER_EXISTING_CHUNKS = false 

export submit_chunk_task, taskproducer, get_origin_set

function get_origin_set( fileNameList::Vector )
    originSet = Set()
    for fileName in fileNameList
        origin = fileName2origin( fileName; prefix = "block_" )
        push!(originSet, origin)
    end
    return originSet
end

function get_origin_set(argDict::Dict)
    # cut out from a big array
    N = length(argDict[:gridsize])
    gridIndexList = Vector{Tuple}()
    originSet = OrderedSet{Vector}()
    # the flag to indicate whether the specific origin was visited
    if isempty(argDict[:continuefrom])
        flag = true
    else
        flag = false
    end
    for gridz in 1:argDict[:gridsize][3]
        for gridy in 1:argDict[:gridsize][2]
            for gridx in 1:argDict[:gridsize][1]
                if 3 < N
                    gridIndex = (gridx, gridy, gridz,
                                    ones(Int, N - 3)...)
                else
                    gridIndex = (gridx, gridy, gridz)
                end
                origin = argDict[:origin] .+ ([gridIndex...] .- 1) .* argDict[:stride]
                if origin == argDict[:continuefrom]
                   flag = true
                end
                if flag
                    push!(originSet, origin)
                end
            end
        end
    end
    return originSet
end

function existing_chunk_filter!( originSet::OrderedSet; 
                                chunkSize::Vector   = [512,512,64],
                                cropMargin::Vector  = [32,32,4],
                                dirPath::String     = "s3://neuroglancer/pinky40_v11/affinitymap-unet/4_4_40/")
    d = S3Dict(dirPath)
    for origin in originSet
        start0 = origin .+ cropMargin .- 1
        stop  = start0 .+ chunkSize 
        chunkFileName = "$(start0[1])-$(stop[1])_$(start0[2])-$(stop[2])_$(start0[3])-$(stop[3])"
        if haskey(d, chunkFileName)
            println("existing chunk, no need to keep: $(chunkFileName)")
            delete!(originSet, origin)
        else 
            println("key not exist: $(chunkFileName), will produce this task")
        end 
    end
end 

function taskproducer( argDict::Dict{Symbol, Any}; originSet = Set{Vector}() )
    task = get_task( argDict[:task] )
    # set gpu id
    set!(task, :deviceID, argDict[:deviceid])
    #@show task

    # the SQS queue as a Julia Channel
    queuename = argDict[:queuename]
    if isempty(queuename)
        println("PRINT TASK JSONS (no queue has been set)")
    else
        c = SQSChannel(queuename)
    end

    # read task config file
    # produce task script
    if isempty( originSet )
        originSet = get_origin_set( argDict )
    end

    # filter out the chunks outside the polygon
#    if IS_USE_POLYGON_FILTER
 #       originSet = polygon_filter( originSet )
 #   end
    if IS_FILTER_EXISTING_CHUNKS 
        existing_chunk_filter!(originSet)
    end 

    for origin in originSet
        set!(task, :origin, origin)
        if isempty(queuename)
            println(JSON.json(task))
        else
            println("start of chunk: $origin")
            put!(c, JSON.json(task))
        end
    end
end

end # end of module
