module Execute

using ..ChunkFlow
using Requests
using SQSChannels

export execute

"""
    customize_task!( task::Dict{Symbol, Any}, argDict::Dict{Symbol, Any} )
modify the task according to local commandline parameters 
"""
function customize_task!( task::Dict{Symbol, Any}, argDict::Dict{Symbol, Any} )
    # set the gpu device id to use
    if !isa(argDict[:deviceid], Void)
        set!(task, :deviceID, argDict[:deviceid])
    end
end

function execute(argDict::Dict{Symbol, Any})
    if argDict[:task]==nothing || isa(argDict[:task], Void)
        # fetch task from AWS SQS
        sqsChannel = SQSChannel( argDict[:awssqs] )
        while true
            local task, msgHanle
            try
                msgHandle, task = fetch( sqsChannel )
            catch err
                @show err
                @show typeof(err)
                if isa(err, BoundsError) && argDict[:shutdown]
                    post_task_finished(queuename)
        		    run(`sudo shutdown -h 0`)
                else
                    rethrow()
                end
            end

            # modify the task according to command line
            customize_task!(task, argDict)

            try
                forward( Net(task) )
            catch err
                if isa(err, ChunkFlow.ZeroOverFlowError)
                    warn("zero overflow!")
                else
                    #rethrow()
		    warn("get en error while execution: $err")
		    continue
                end
            end

            # delete task message in SQS
            delete!(c, msgHandle)
            sleep(1)
        end
    else
        # has local task definition
        task = get_task(argDict[:task])
        if !isa(argDict[:deviceid], Void)
            set!(task, :deviceID, argDict[:deviceid])
        end
        net = Net(task)
        forward(net)
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
