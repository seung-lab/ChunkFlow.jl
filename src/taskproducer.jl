using EMIRT
using DataStructures

include("aws/task.jl")
include("bigarray/backends/aligned.jl")
include("chunk/producer.jl")

# read task config file
@assert length(ARGS)==1
task = get_task()
@show task


function produce_tasks_s3img(task::Ttask)
    # get list of files, no folders
    @show task[:input][:inputs][:fname]
    bkt, keylst = s3_list_objects(task[:input][:inputs][:fname])
    @assert length(keylst)>0
    for key in keylst
        task[:input][:inputs][:fname] = joinpath("s3://", bkt, key)
        str_task = task2str(task)
        # send the task to SQS queue
        sendSQSmessage(env, sqsname, str_task)
    end
end

function produce_tasks_local(task::Ttask)
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
        sendSQSmessage(env, sqsname, str_task)
    end
end

"""
produce chunks and corresponding tasks to AWS SQS
"""
function produce_chunks_tasks(task::Ttask)
    inputs = task[:bigarray][:inputs]
    @assert contains(task[:bigarray][:kind], "bigarray")
    # get chunk from a big array
    fregister = joinpath(inputs[:fdataset],inputs[:faligned],inputs[:fregister])
    barr = AlignedBigArray(fregister)

    # get chunks
    params = task[:chunks][:params]
    @assert contains(task[:chunks][:kind], "chunks")
    chks = Tchks(barr, params[:origin], params[:chksz],
                params[:overlap], params[:gridsz], params[:voxelsize])

    # produce chunks
    for chk in chks
        # save or upload chunk
        fchk = "$(task[:chunks][:outputs][:fchkpre])$(chk.origin[1])_$(chk.origin[2])_$(chk.origin[3]).h5"
        if iss3(fchk)
            ftmp = tempname()*".h5"
            save(ftmp, chk)
            run(`aws s3 mv $ftmp $fchk`)
        else
            save(fchk, chk)
        end

        # produce task json file to aws simple queue
        task[:input][:inputs][:fname] = fchk
        str_task = task2str(task)
        println("produced a new task: ")
        @show str_task
        sendSQSmessage(env, sqsname, str_task)
    end
end

# produce task script
task = get_task()
produce_chunks_tasks(task)
