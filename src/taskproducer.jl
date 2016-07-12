using EMIRT

include("aws/task.jl")

const env = build_env()
const sqsname = "spipe-tasks"

# read task config file
@assert length(ARGS)==1
task = get_task()
@show task
# get list of files, no folders
@show task[:input][:inputs][:fname]
bkt, keylst = s3_list_objects(task[:input][:inputs][:fname])
@assert length(keylst)>0

if length(keylst)==0
    error("no such file in AWS S3!")
elseif length(keylst)==1
    # directly send the task to SQS queue
    sendSQSmessage(env, sqsname, task)
else
    for key in keylst
        task[:input][:inputs][:fname] = joinpath("s3://", bkt, key)
        # convert to string
        ftmp = tempname()
        f = open(ftmp, "w")
        JSON.print(f, task)
        close(f)
        str_task = readall(ftmp)
        # send the task to SQS queue
        sendSQSmessage(env, sqsname, str_task)
    end
end
