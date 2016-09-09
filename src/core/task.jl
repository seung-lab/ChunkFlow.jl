using JSON
using DataStructures

include("types.jl")
include(joinpath(Pkg.dir(), "EMIRT/plugins/cloud.jl"))

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
    msg = fetchSQSmessage(ASCIIString(queuename))
    task = msg.body
    # transform text to JSON OrderedDict format
    return JSON.parse(task, dicttype=OrderedDict{Symbol, Any}), msg
end

function get_s3_task(fileName::AbstractString)
    @assert iss3(fileName)
    lcfile = download(ARGS[1], "/tmp/")
    str_task = readall( lcfile )
    # transform text to JSON OrderedDict format
    return JSON.parse(str_task, dicttype=OrderedDict{Symbol, Any})
end

function get_local_task(fileName::AbstractString)
    # just simple local file
    str_task = readall( fileName )
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
    if iss3( ftask )
        task = get_s3_task( ftask )
    elseif isfile( ftask )
        task = get_local_task( ftask )
    else
        error("input should be a s3 or local task configuration file in JSON format! \n input task file: $ftask")
    end
end

"""
produce tasks to AWS SQS
"""
function produce_tasks_s3img(task::ChunkFlowTask)
    # get list of files, no folders
    @show task[:input][:inputs][:fileName]
    bkt, keylst = s3_list_objects( task[:input][:inputs][:fileName] )
    @assert length(keylst)>0
    for key in keylst
      @show joinpath("s3://", bkt, key)
      task[:input][:inputs][:fileName] = joinpath("s3://", bkt, key)
      # send the task to SQS queue
      sendSQSmessage(sqsname, JSON.json(task))
    end
end


function produce_tasks_local(task::ChunkFlowTask)
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
        str_task = task2str(task)
        sendSQSmessage(sqsname, str_task)
    end
end
