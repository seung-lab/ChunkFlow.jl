include("aws.jl")
include("task.jl")
using EMIRT

const global env = build_env()

# read task config file
task = readall(ARGS[1])

pd = configparser(task)
@assert iss3( pd["gn"]["fimg"] )

# get list of files, no folders
bkt, keylst = s3_list_objects(env, pd["gn"]["fimg"])
@assert length(keylst)>0
if length(keylst)==1
    # directly send the task to SQS queue
    sendSQSmessage(env, "spipe-tasks", task)
else
    lines = split(task, "\n")
    for key in keylst
        # a new task
        newtask = ""
        # make a new task with this specific file name
        for i in length(lines)
            line = lines[i]
            line = replace(line, " ", "")*"\n"
            if ismatch(r"^fimg", line)
                line = "fimg=s3://"*joinpath(bkt, key)*"\n"
            end
            # add the line to new task
            newtask *= line
        end
        # send the task to SQS queue
        sendSQSmessage(env, "spipe-tasks", newtask)
    end
end
