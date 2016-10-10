using JSON
using DataStructures

typealias ChunkFlowTask OrderedDict{Symbol, Any}

typealias ChunkFlowTaskList Vector{ChunkFlowTask}

include(joinpath(Pkg.dir(), "EMIRT/plugins/cloud.jl"))

"""
set the some key to specific value
"""
function set!(task::ChunkFlowTask, key::Symbol, value::Any)
    if value==Void || value==nothing
        return task
    end
    for (edgeName, edgeConfig) in task
        if haskey(edgeConfig[:params], key)
            task[edgeName][:params][key] = value
        end
    end
end

function get_sqs_task(queuename::AbstractString = AWS_SQS_QUEUE_NAME)
    msg = fetchSQSmessage(String(queuename))
    task = msg.body
    # transform text to JSON OrderedDict format
    return JSON.parse(task, dicttype=ChunkFlowTask), msg
end

function get_s3_task(fileName::AbstractString)
    @assert iss3(fileName)
    lcfile = download(ARGS[1], "/tmp/")
    str_task = readstring( lcfile )
    # transform text to JSON OrderedDict format
    return JSON.parse(str_task, dicttype=ChunkFlowTask)
end

function get_local_task(fileName::AbstractString)
    # just simple local file
    str_task = readstring( fileName )
    # transform text to JSON OrderedDict format
    return JSON.parse(str_task, dicttype=ChunkFlowTask)
end

"""
get task from AWS Simple queue
"""
function get_task()
    get_sqs_task()
end

function get_task(ftask::AbstractString)
    if iss3( ftask )
        task = get_s3_task( ftask )
    elseif isfile( ftask )
        task = get_local_task( ftask )
    else
        error("input should be a s3 or local task configuration file in JSON format! \n input task file: $ftask")
    end
end

function get_task(ftask::Void)
    return nothing
end

"""
submit tasks to AWS SQS
"""
function submit(tasks::ChunkFlowTaskList; sqsQueueName::AbstractString = AWS_SQS_QUEUE_NAME)
    for task in tasks
        # send the task to SQS queue
        sendSQSmessage(awsEnv, sqsQueueName, JSON.json(task))
    end
end

function submit(task::ChunkFlowTask; sqsQueueName::AbstractString = AWS_SQS_QUEUE_NAME)
    # send the task to SQS queue
    sendSQSmessage(awsEnv, sqsQueueName, JSON.json(task))
end

"""
produce tasks to AWS SQS
"""
function produce_tasks(task::ChunkFlowTask)
    @assert task[:input][:kind] == :readh5
    if iss3(task[:input][:inputs][:fileName])
        return produce_tasks_s3img(task)
    else
        return produce_tasks_local(task)
    end
end

function produce_tasks_s3img(task::ChunkFlowTask)
    # a list of tasks
    ret = ChunkFlowTaskList()
    # get list of files, no folders
    @show task[:input][:inputs][:fileName]
    bkt, keylst = s3_list_objects( task[:input][:inputs][:fileName] )
    @assert length(keylst)>0
    for key in keylst
        @show joinpath("s3://", bkt, key)
        task[:input][:inputs][:fileName] = joinpath("s3://", bkt, key)
        push!(ret, task)
    end
    return ret
end


function produce_tasks_local(task::ChunkFlowTask)
    ret = ChunkFlowTaskList()

    @show task[:input][:inputs][:fileName]
    # directory name and prefix
    dn, prefix = splitdir(task[:input][:inputs][:fileName])
    fileNames = readdir(dn)
    @assert length(fileNames)>0
    for fileName in fileNames
        if !contains(basename(fileName), prefix)
            # contains is not quite accurate
            # todo: using ismatch to check starting with prefix
            info("excluding file: $(fileName)")
            continue
        end
        task[:input][:inputs][:fileName] = joinpath(dn, fileName)
        push!(ret, task)
    end
    return ret
end
