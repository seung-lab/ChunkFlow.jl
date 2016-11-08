module Producer

using ..ChunkNet
using DataStructures

export taskproducer

function submit_chunk_task(argDict::Dict{Symbol, Any},
                            gridIndex::Tuple,
                            task::ChunkFlowTask)

    origin = argDict[:origin] .+ ([gridIndex...] .- 1) .* argDict[:stride]

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
    submit(task)
end

function taskproducer( argDict::Dict{String, Any} )
    task = get_task( argDict[:task] )
    # set gpu id
    set!(task, :deviceID, argDict[:deviceid])
    @show task

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
        for gridz in 1:argDict[:gridsize][3]
            for gridy in 1:argDict[:gridsize][2]
                for gridx in 1:argDict[:gridsize][1]
                    if 3 < N
                        push!(gridIndexList,
                                (gridx, gridy, gridz,
                                    ones(Int, N - 3)...))
                    else
                        push!(gridIndexList, (gridx, gridy, gridz))
                    end
                end
            end
        end
        # Threads.@threads for idx in gridIndexList
        #     process_task(idx)
        # end
        map(submit_chunk_task, argDict, gridIndexList, task)
    else
        error("invalid input method: $(task[:input][:kind])")
    end
end

end # end of module
