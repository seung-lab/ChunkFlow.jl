module Execute

using ..ChunkFlow
using Requests
using SQSChannels
using JSON
using DataStructures

export execute

"""
    customize_task!( task::Dict{Symbol, Any}, argDict::Dict{Symbol, Any} )
modify the task according to local commandline parameters
"""
function customize_task!( task::Associative, argDict::Associative )
    # set the gpu device id to use
    if !isa(argDict[:deviceid], Void)
        set!(task, :deviceID, argDict[:deviceid])
        println("set deviceid as $(argDict[:deviceid])")
    end
end

function execute(argDict::Dict{Symbol, Any})
    if argDict[:task]==nothing || isa(argDict[:task], Void)
        # fetch task from AWS SQS
        sqsChannel = SQSChannel( argDict[:queuename] )
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
	        task = JSON.parse(taskString; dicttype=OrderedDict{Symbol, Any})
            # modify the task according to command line
            if isa(task, String)
                task = JSON.parse(task;
                    dicttype=OrderedDict{Symbol, Any})
            end
            customize_task!(task, argDict)

            try
                forward( Net(task) )
            catch err
                if isa(err, ChunkFlow.ZeroOverFlowError)
                    println("too many zeros!")
                else
                    #rethrow()
		            warn("get an error while execution: $err")
                    @show typeof(err)
		            continue
                end
            end

            # delete task message in SQS
            println("deleting task: $msgHandle")
            delete!(sqsChannel, msgHandle)
            sleep(1)
        end
    else
        # has local task definition
        task = get_task(argDict[:task])
        if !isa(argDict[:deviceid], Void)
            set!(task, :deviceID, argDict[:deviceid])
        end
        @show task
        try 
            forward( Net(task) )
        catch err
            if isa(err, ChunkFlow.ZeroOverFlowError)
                warn("too many zeros!")
            else 
                println("catch an error while executing the task: $err")
                rethrow()
            end 
        end 
    end
end

"""
    post_task_finished(queuename::AbstractString)
post task status to slack
"""
function post_task_finished( queuename::AbstractString )
    # this link point to jingpengw's slack private channel
    post(URI("https://hooks.slack.com/services/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"),
            """{"text": "pipeline tasks in $(queuename) finished!"}""")
end

end # end of module
