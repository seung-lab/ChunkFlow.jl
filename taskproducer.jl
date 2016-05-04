include("aws.jl")
include("task.jl")
using EMIRT

const global env = build_env()

# read task config file
task = readall(ARGS[1])

pd = configparser(task)
if ( pd["gn"]["fimg"] )


# send the task to SQS queue
sendSQSmessage(env, "spipe-tasks", task)
