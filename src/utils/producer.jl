module Producer

using ..ChunkFlow
using DataStructures
using BigArrays.Utils
using SQSChannels
using JSON

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

function taskproducer( argDict::Dict{Symbol, Any}; originSet = Set{Vector}() )
    task = get_task( argDict[:task] )
    # set gpu id
    set!(task, :deviceID, argDict[:deviceid])
    #@show task

    # the SQS queue as a Julia Channel
    c = SQSChannel( argDict[:queuename] )
    # read task config file
    # produce task script
    if contains(task[:input][:kind], "readh5")
        tasks = produce_tasks(task)
        submit(tasks)
    elseif  contains(task[:input][:kind], "cutoutchunk") ||
            contains(task[:input][:kind], "readchunk")
        if isempty( originSet )
            originSet = get_origin_set( argDict )
        end

        for origin in originSet
            println("start of chunk: $origin")
            set!(task, :origin, origin)
            put!(c, JSON.json(task))
        end
    else
        error("invalid input method: $(task[:input][:kind])")
    end
end

end # end of module
