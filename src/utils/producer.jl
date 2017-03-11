module Producer

using ..ChunkFlow
using DataStructures
using BigArrays.Utils

export submit_chunk_task, taskproducer, get_origin_set

function get_origin_set( fileNameList::Vector )
    # fileNames = readstring(`gsutil ls gs://zfish/all_7/hypersquare/`)
    # fileList = split(fileNames)
    originSet = Set()
    for fileName in fileNameList
        # fileName = split(fileName,"/")[end-1]
        #     @show fileName
        # fields = split(fileName, "_")[2:end]
        # origin = map(x->parse(split(x,"-")[1]), fields)
        #     @show origin
        # origin .-= [64,64,8]
        # push!(origin, 1)
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
    flag = false
    for gridz in 1:argDict[:gridsize][3]
        for gridy in 1:argDict[:gridsize][2]
            for gridx in 1:argDict[:gridsize][1]
                if 3 < N
                    # push!(gridIndexList,
                    #         (gridx, gridy, gridz,
                    #             ones(Int, N - 3)...))
                    gridIndex = (gridx, gridy, gridz,
                                    ones(Int, N - 3)...)
                else
                    # push!(gridIndexList, (gridx, gridy, gridz))
                    gridIndex = (gridx, gridy, gridz)
                end
                origin = argDict[:origin] .+ ([gridIndex...] .- 1) .* argDict[:stride]
                #if flag
                    push!(originSet, origin)
                #end
                if origin == [47105,6145,257]
                   flag = true
                end
            end
        end
    end
    return originSet
end

# const originSet = get_origin_set()
# println("originSet = $(originSet)")
"""
    submit_chunk_task(argDict::Dict{Symbol, Any}, origin::Vector, task::ChunkFlowTask)
submit a task corresponds to a specific chunk

Parameters:
- argDict: commandline arguments
- origin:  the origin of this specific chunk
- task: the Dict defines computation task and parameters

Output:
- generate a task dict and turns to string, submit it to SQS queue
"""
function submit_chunk_task(argDict::Dict{Symbol, Any},
                            origin::Vector,
                            task::ChunkFlowTask)

    # origin = argDict[:origin] .+ ([gridIndex...] .- 1) .* argDict[:stride]

    producer = get_task( argDict[:producer] )
    if producer != nothing
        # produce chunk
        try
            set!(producer, :origin, origin)
            forward( Net(producer) )
        catch err
            if isa( err, ZeroOverFlowError )
                warn("zero overflow in this chunk!")
                return
            else
                rethrow()
            end
        end
    end
    # submit the corr
    set!(task, :origin, origin)

    ## ignore positive part
    # if any(origin.<0)
    #     submit(task; sqsQueueName = argDict[:awssqs])
    # end

    # ignore existing files
    # dstSize = [1024,1024,128]
    # offset = [16384,16384,16384]
    # dstOrigin = origin .+ [54,54,4] .+ offset
    # dstStop = dstOrigin .+ dstSize .- 1
    # dstFileName = "/usr/people/jingpeng/seungmount/research/Jingpeng/14_zfish/"*
    #                "jknet/4x4x4/affinitymap/block_"*
    #                "$(dstOrigin[1])-$(dstStop[1])_"*
    #                "$(dstOrigin[2])-$(dstStop[2])_"*
    #                "$(dstOrigin[3])-$(dstStop[3])_1-3.h5"
    # if !isfile(dstFileName)
    #     info("submitting task with origin: $(origin) to queue $(argDict[:awssqs])")
    #     submit(task; sqsQueueName = argDict[:awssqs])
    # else
    #     info("affinity chunk exist: $(dstFileName)")
    # end

    # ignore existing files
    # if origin in originSet
    #     println("origin exists: $(origin)")
    # else
    #     info("submitting task with origin: $(origin) to queue $(argDict[:awssqs])")
    #     submit(task; sqsQueueName = argDict[:awssqs])
    # end

    ## submit all the tasks
    info("submitting task with origin: $(origin) to queue $(argDict[:awssqs])")
    submit(task; sqsQueueName = argDict[:awssqs])
end

function taskproducer( argDict::Dict{Symbol, Any}; originSet = Set{Vector}() )
    task = get_task( argDict[:task] )
    # set gpu id
    set!(task, :deviceID, argDict[:deviceid])
    @show task

    flag = false
    # read task config file
    # produce task script
    if contains(task[:input][:kind], "readh5")
        # tasks = ChunkFlowTaskList()
        tasks = produce_tasks(task)
        submit(tasks)
    elseif  contains(task[:input][:kind], "cutoutchunk") ||
            contains(task[:input][:kind], "readchunk")
        if isempty( originSet )
            originSet = get_origin_set( argDict )
        end
        # Threads.@threads for idx in gridIndexList
        #     process_task(idx)
        # end
        map(x-> submit_chunk_task(argDict, x, task), originSet)
    else
        error("invalid input method: $(task[:input][:kind])")
    end
end

end # end of module
