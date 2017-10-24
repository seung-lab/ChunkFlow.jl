module ChunkFlowTasks 

using ..ChunkFlow
using Requests
using SQSChannels
using JSON
using DataStructures

export ChunkFlowTask 
                                                  
typealias ChunkFlowTask OrderedDict{Symbol, Any}  

export execute

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

function execute( task::ChunkFlowTask )
    @show task
    try 
        forward( task )
    catch err
        if isa(err, ChunkFlow.ZeroOverFlowError)
            warn("the input has too many zeros!")
        else 
            println("catch an error while executing the task: $err")
            rethrow()
        end 
    end
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
        task = JSON.parse(taskString; dicttype=OrderedDict{Symbol, Any})
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
        task = JSON.parsefile(argDict[:task]; dicttype=OrderedDict{Symbol, Any})
        customize_task!(task, argDict)
        execute(task) 
    end
end

"""
    post_task_finished(queuename::AbstractString)
post task status to slack
"""
function post_task_finished( queuename::AbstractString, slackHookLink::AbstractString )
    # this link point to jingpengw's slack private channel
    post(URI( slackHookLink ),
            """{"text": "pipeline tasks in $(queuename) finished!"}""")
end

end # end of module
