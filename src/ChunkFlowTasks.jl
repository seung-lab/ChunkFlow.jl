module ChunkFlowTasks
using ..ChunkFlow 
using ..Edges

using AWSCore
using AWSSQS
using JSON
import DataStructures: OrderedDict 

using ChunkFlow.Utils.AWSCloudWatches 

export ChunkFlowTask, execute 
                                                  
const ChunkFlowTask = OrderedDict{Symbol, Any}  

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
        set!(task,:deviceID,  argDict[:deviceid])
        println("set deviceid as $(argDict[:deviceid])")
    end
end

function set!(task::Associative, key, value)
    for k in keys(task)
        if k==key
            task[k] = value 
        elseif isa(task[k], Associative)
            set!( task[k], key, value )
        end 
    end 
end 

"""
construct a net from computation graph config file.
currently, the net was composed by edges/layers
all the edges was stored and managed in a DictChannel.
"""
function execute( task::OrderedDict{Symbol, Any} )
    # the global dict channel 
    c = Dict{String, Channel}()
    t = AWSCloudWatches.Timer()
    for (name, d) in task 
        info("----- start $(name) -----")
        edge = eval(Symbol(d[:kind]))()
        try 
            Edges.run(edge, c, d)
        catch err 
            if isa(err, ChunkFlow.ZeroOverFlowError)
				warn("the input has too many zeros!")
                break
			else 
				println("catch an error while executing the task: $err")
				rethrow()
			end
		end 
        elapsed = AWSCloudWatches.get_elapsed!(t)
        AWSCloudWatches.record_elapsed(name, elapsed)
        info("---- elapse of $(name): $(elapsed) -----")
    end
    total_elapsed = AWSCloudWatches.get_total_elapsed(t)
    #AWSCloudWatches.record_elapsed("TotalPipeline", total_elapsed)
    AWSCloudWatches.info("------ total elapsed of pipeline: $(total_elapsed) --------")
end


function execute_sqs_tasks( sqsQueue::AWSSQS.AWSQueue; 
                            argDict::Dict{Symbol,Any} = Dict{Symbol,Any}() )
    local taskString, m
    while true
        local task, msgHandle
        try
            m = sqs_receive_message( sqsQueue )
        catch err
            @show err
            @show typeof(err)
            if isa(err, BoundsError)
                post_task_finished(argDict[:queuename])
                if argDict[:shutdown]
                    run(`shutdown -h 0`)
                end
                # sucess, break the loop and return peacefully
                break
            else
                rethrow()
            end
        end
        task = ChunkFlowTask( m[:message] )
        # modify the task according to command line
        customize_task!(task, argDict)
        
        execute(task)

        # delete task message in SQS
        println("deleting task in queue...")
        sqs_delete_message(sqsQueue, m)
        sleep(1)
    end
end 

function execute( argDict::Dict{Symbol, Any} )
    if argDict[:task]==nothing || isa(argDict[:task], Void)
        # fetch task from AWS SQS
        if !haskey(ENV, "AWS_ACCESS_KEY_ID") && isfile("/secrets/aws-secret.json") 
            d = JSON.parsefile("/secrets/aws-secret.json")
            for (k,v) in d 
                ENV[k] = v
            end 
        end 
        aws = AWSCore.aws_config()
        sqsQueue = sqs_get_queue(aws, argDict[:queuename])
        execute_sqs_tasks( sqsQueue; argDict = argDict )
    else
        # has local task definition
        task = JSON.parsefile(argDict[:task]; dicttype=ChunkFlowTask)
        customize_task!(task, argDict)
        execute(task) 
    end
end

end # end of module
