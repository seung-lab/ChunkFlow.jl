module Producer

using ..ChunkFlow
using DataStructures

export submit_chunk_task, taskproducer

function get_origin_set()
    fileNames = readstring(`gsutil ls gs://zfish/all_7/hypersquare/`)
    fileList = split(fileNames)
    originSet = Set()
    for fileName in fileList
        fileName = split(fileName,"/")[end-1]
        #     @show fileName
        fields = split(fileName, "_")[2:end]
        origin = map(x->parse(split(x,"-")[1]), fields)
        #     @show origin
        origin .-= [64,64,8]
        push!(origin, 1)
        push!(originSet, origin)
    end
    return originSet
end

# const originSet = get_origin_set()
# println("originSet = $(originSet)")

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

function taskproducer( argDict::Dict{Symbol, Any} )
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
        # cut out from a big
        N = length(argDict[:gridsize])
        gridIndexList = Vector{Tuple}()
        originList = Vector{Vector}()
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
                        push!(originList, origin)
                    #end
                    if origin ==  [5067,38859,17355]
                       flag = true
                    end
                end
            end
        end
        # Threads.@threads for idx in gridIndexList
        #     process_task(idx)
        # end
        map(x-> submit_chunk_task(argDict, x, task), originList)
    else
        error("invalid input method: $(task[:input][:kind])")
    end
end

end # end of module
