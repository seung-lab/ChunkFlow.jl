include("aws.jl")

const global env = build_env()

# read task config file
task = readall(ARGS[1])

# send the task to SQS queue
sendSQSmessage(env, "spipe-tasks", task)
