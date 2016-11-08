module Execute

using ..ChunkNet

function execute(argDict::Dict{Symbol, Any})
    if argDict[:task]==nothing || isa(argDict[:task], Void)
        # fetch task from AWS SQS
        while true
            task, msg = get_task()

            # set the gpu device id to use
            if !isa(argDict[:deviceid], Void)
                set!(task, :deviceID, argDict[:deviceid])
            end
            @show task

            try
                forward( Net(task) )
            catch err
                if isa(err, LoadError) && argDict[:shutdown]
                    # automatically terminate the instance / machine
                    run(`sudo shutdown -h 0`)
                elseif isa(err, ChunkNet.ZeroOverFlowError)
                    warn("zero overflow!")
                else
                    rethrow()
                end
            end

            # delete task message in SQS
            deleteSQSmessage!(msg, AWS_SQS_QUEUE_NAME)
            sleep(5)
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

end # end of module
