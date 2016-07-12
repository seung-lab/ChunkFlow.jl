using JSON
using DataStructures

include(joinpath(Pkg.dir(), "EMIRT/src/plugins/aws.jl"))

const sqsname = "spipe-tasks"

export get_task

function get_sqs_task(queuename::ASCIIString = sqsname)
    env = build_env()
    msg = takeSQSmessage!(env, queuename)
    task = msg.body
    # transform text to JSON OrderedDict format
    return JSON.parse(task, dicttype=OrderedDict{Symbol, Any})
end

function get_s3_task(fname::AbstractString)
    @assert iss3(fname)
    env = build_env()
    lcfile = download(env, ARGS[1], "/tmp/")
    task = readlines( lcfile )
    # transform text to JSON OrderedDict format
    return JSON.parse(task, dicttype=OrderedDict{Symbol, Any})
end

function get_local_task(fname::AbstractString)
    # just simple local file
    task = readall( fname )
    # transform text to JSON OrderedDict format
    return JSON.parse(task, dicttype=OrderedDict{Symbol, Any})
end

"""
get task from AWS Simple queue
"""
function get_task()
    # parse the config file
    if length(ARGS)==0
        return get_sqs_task()
    else
        if length(ARGS)>1
            warn("too many input arguments, use the first one only!")
        end
        if iss3( ARGS[1] )
            return get_s3_task(ARGS[1])
        elseif isfile(ARGS[1])
            return get_local_task(ARGS[1])
        else
            error("input should be a s3 or local task configuration file in JSON format!")
        end
    end
end
