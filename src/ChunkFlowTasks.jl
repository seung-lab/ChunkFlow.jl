module ChunkFlowTasks
using ..ChunkFlow 
using ..Nodes
using SQSChannels
using JSON
using DataStructures
include("utils/AWSCloudWatches.jl"); using .AWSCloudWatches

export ChunkFlowTask, execute 
                                                  
typealias ChunkFlowTask OrderedDict{Symbol, Any}  

function ChunkFlowTask( taskString::AbstractString )
    JSON.parse(taskString, dicttype=ChunkFlowTask)
end 

"""
    customize_task!( task::Dict{Symbol, Any}, argDict::Dict{Symbol, Any} )
modify the task according to local commandline parameters
"""
function customize_task!( task::Associative, argDict::Associative )
    if isempty( argDict )
        return 
    end 
    # set the gpu device id to use
    if !isa(argDict[:deviceid], Void)
        set!(task, :deviceID, argDict[:deviceid])
        println("set deviceid as $(argDict[:deviceid])")
    end
end

"""
construct a net from computation graph config file.
currently, the net was composed by nodes/layers
all the nodes was stored and managed in a DictChannel.
"""
function execute( task::OrderedDict{Symbol, Any} )
    # the global dict channel 
    c = Dict{String, Channel}()
    t = AWSCloudWatches.Timer()
    for (name, d) in task 
        AWSCloudWatches.info("----- start $(name) -----")
        node = eval(Symbol(d[:kind]))()
        try 
            Nodes.run(node, c, d)
        catch err 
            if isa(err, ChunkFlow.ZeroOverFlowError)
				warn("the input has too many zeros!")
			else 
				println("catch an error while executing the task: $err")
				rethrow()
			end
		end 
        elapsed = AWSCloudWatches.get_elapsed!(t)
        AWSCloudWatches.record_elapsed(name, elapsed)
        AWSCloudWatches.info("---- elapse of $(name): $(elapsed) -----")
    end
    total_elapsed = AWSCloudWatches.get_total_elapsed(t)
    AWSCloudWatches.record_elapsed("TotalPipeline", total_elapsed)
    AWSCloudWatches.info("------ total elapsed of pipeline: $(total_elapsed) --------")
end


function execute( sqsChannel::SQSChannel; argDict::Dict{Symbol,Any} = Dict{Symbol,Any}() )
    local taskString, msgHandle
    while true
        local task, msgHandle
        try
            msgHandle, taskString = fetch( sqsChannel )
        catch err
            @show err
            @show typeof(err)
            if isa(err, BoundsError)
                post_task_finished(argDict[:queuename])
                if argDict[:shutdown]
                    run(`sudo shutdown -h 0`)
                end
                # sucess, break the loop and return peacefully
                break
            else
                rethrow()
            end
        end
        task = ChunkFlowTask( taskString )
        # modify the task according to command line
        customize_task!(task, argDict)

        # delete task message in SQS
        println("deleting task: $msgHandle")
        delete!(sqsChannel, msgHandle)
        sleep(1)
    end
end 

function execute( argDict::Dict{Symbol, Any} )
    if argDict[:task]==nothing || isa(argDict[:task], Void)
        # fetch task from AWS SQS
        sqsChannel = SQSChannel( argDict[:queuename])
        execute( sqsChannel; argDict = argDict )
    else
        # has local task definition
        task = JSON.parsefile(argDict[:task]; dicttype=ChunkFlowTask)
        customize_task!(task, argDict)
        execute(task) 
    end
end

end # end of module
