using EMIRT
using DataStructures

include("aws/task.jl")

# read task config file
@assert length(ARGS)==1
ftask = ARGS[1]

# produce task script
task = get_task(ftask)

if iss3(task[:input][:inputs][:fname])
    produce_tasks_s3img(task)
else
    produce_tasks_local(task)
end
