using JSON
using DataStructures

include("../core/types.jl")
include(joinpath(Pkg.dir(), "EMIRT/plugins/aws.jl"))

"""
set the gpuid for all functions
"""
function set_gpu_id!(task::ChunkFlowTask, gpuid::Int)
  for (edgeName, edgeConfig) in task
    if haskey(edgeConfig[:params], :GPUID)
      task[edgeName][:params][:GPUID] = gpuid
    end
  end
end

function get_sqs_task(queuename::AbstractString = sqsname)
    msg = fetchSQSmessage(awsEnv, ASCIIString(queuename))
    task = msg.body
    # transform text to JSON OrderedDict format
    return JSON.parse(task, dicttype=OrderedDict{Symbol, Any}), msg
end

function get_s3_task(fname::AbstractString)
    @assert iss3(fname)
    lcfile = download(awsEnv, ARGS[1], "/tmp/")
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
function produce_tasks_s3img(task::ChunkFlowTask)
    # get list of files, no folders
    @show task[:input][:inputs][:fname]
    bkt, keylst = s3_list_objects( task[:input][:inputs][:fname] )
    @assert length(keylst)>0
    for key in keylst
        task[:input][:inputs][:fname] = joinpath("s3://", bkt, key)
        # send the task to SQS queue
        sendSQSmessage(awsEnv, sqsname, JSON.json(task))
    end
end


function produce_tasks_local(task::ChunkFlowTask)
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
        sendSQSmessage(awsEnv, sqsname, str_task)
    end
end
