include("aws.jl")
include("task.jl")
using EMIRT

const global env = build_env()

# read task config file
task = readall(ARGS[1])

pd = configparser(task)
@assert iss3( pd["gn"]["fimg"] )

# get list of files, no folders
lf = s3_list_objects(env, pd["gn"]["fimg"])
for f in lf
    # make a new task with this specific file name

    # send the task to SQS queue
    sendSQSmessage(env, "spipe-tasks", task)
end
