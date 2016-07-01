include("core/aws.jl")
include("core/task.jl")
using EMIRT
include(joinpath(Pkg.dir(), "EMIRT/src/plugins/aws.jl"))

const global env = build_env()

# read task config file
task = readall(ARGS[1])
pd = configparser(task)
@assert iss3( pd["gn"]["fimg"] )
@show pd

# get list of files, no folders
bkt, keylst = s3_list_objects(env, pd["gn"]["fimg"])
@show bkt
@show keylst
@assert length(keylst)>0

if length(keylst)==1
    # directly send the task to SQS queue
    sendSQSmessage(env, "spipe-tasks", task)
else
    lines = split(task, "\n")
    @show lines
    for key in keylst
        # a new task
        newtask = ""
        # make a new task with this specific file name
        for i in 1:length(lines)
            line = lines[i]
            @show line
            line = replace(line, " ", "")
            if ismatch(r"^fimg", line)
                line = string("fimg=s3://", joinpath(bkt, key))
            end
            # add the line to new task
            newtask = string(newtask, line, "\n")
            @show newtask
        end
        # send the task to SQS queue
        @show newtask
        sendSQSmessage(env, "spipe-tasks", newtask)
    end
end
