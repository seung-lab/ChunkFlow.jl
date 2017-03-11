module Execute

using ..ChunkFlow
using Requests

export execute

function execute(argDict::Dict{Symbol, Any})
    if argDict[:task]==nothing || isa(argDict[:task], Void)
        # fetch task from AWS SQS
        while true
            local task, msg
            try
                task, msg = get_sqs_task(queuename=argDict[:awssqs])
            catch err
                @show err
                @show typeof(err)
                if isa(err, BoundsError)
                    post_task_finished(queuename)
                else
                    rethrow()
                end
            end

            # set the gpu device id to use
            if !isa(argDict[:deviceid], Void)
                set!(task, :deviceID, argDict[:deviceid])
            end

            try
                forward( Net(task) )
            catch err
                if isa(err, LoadError) && argDict[:shutdown]
                    # automatically terminate the instance / machine
                    run(`sudo shutdown -h 0`)
                elseif isa(err, ChunkFlow.ZeroOverFlowError)
                    warn("zero overflow!")
                else
                    rethrow()
                end
            end

            # delete task message in SQS
            deleteSQSmessage!(msg, argDict[:awssqs])
            sleep(3)
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
