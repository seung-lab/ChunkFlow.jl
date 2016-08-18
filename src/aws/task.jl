using JSON
using DataStructures

typealias Ttask OrderedDict{Symbol, Any}

include(joinpath(Pkg.dir(), "EMIRT/plugins/aws.jl"))

global const sqsname = "spipe-tasks"
global const env = build_env()

export get_task

function get_sqs_task(queuename::ASCIIString = sqsname)
    env = build_env()
    msg = fetchSQSmessage(env, queuename)
    task = msg.body
    # transform text to JSON OrderedDict format
    return JSON.parse(task, dicttype=OrderedDict{Symbol, Any}), msg
end

function get_s3_task(fname::AbstractString)
    @assert iss3(fname)
    env = build_env()
    lcfile = download(env, ARGS[1], "/tmp/")
    str_task = readall( lcfile )
    # transform text to JSON OrderedDict format
    return JSON.parse(str_task, dicttype=OrderedDict{Symbol, Any})
end

function get_local_task(fname::AbstractString)
    # just simple local file
    str_task = readall( fname )
    # transform text to JSON OrderedDict format
    return JSON.parse(str_task, dicttype=OrderedDict{Symbol, Any})
end

"""
get task from AWS Simple queue
"""
function get_task()
    get_sqs_task()
end

function get_task(ftask::AbstractString)
    if contains( ftask, "s3://" )
        task = get_s3_task( ftask )
    elseif isfile( ftask )
        task = get_local_task( ftask )
    else
        error("input should be a s3 or local task configuration file in JSON format!")
    end
end

"""
produce tasks to AWS SQS
"""
function produce_tasks_s3img(task::Ttask)
    # get list of files, no folders
    @show task[:input][:inputs][:fname]
    bkt, keylst = s3_list_objects(task[:input][:inputs][:fname])
    @assert length(keylst)>0
    for key in keylst
        task[:input][:inputs][:fname] = joinpath("s3://", bkt, key)
        # send the task to SQS queue
        sendSQSmessage(env, sqsname, JSON.json(task))
    end
end


function produce_tasks_local(task::Ttask)
    @show task[:input][:inputs][:fname]
    # directory name and prefix
    dn, prefix = splitdir(task[:input][:inputs][:fname])
    fnames = readdir(dn)
    @assert length(fnames)>0
    for fname in fnames
        if !contains(basename(fname), prefix)
            # contains is not quite accurate
            # todo: using ismatch to check starting with prefix
            info("excluding file: $(fname)")
            continue
        end
        task[:input][:inputs][:fname] = joinpath(dn, fname)
        str_task = task2str(task)
        sendSQSmessage(env, sqsname, str_task)
    end
end
