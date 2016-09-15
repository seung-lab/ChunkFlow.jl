using BigArrays

"""
produce chunks and corresponding tasks to AWS SQS
"""
function produce_chunks_tasks(task::ChunkFlowTask)
    inputs = task[:bigarray][:inputs]
    @assert contains(task[:bigarray][:kind], "bigarray")
    # get chunk from a big array
    fregister = joinpath(inputs[:fdataset],inputs[:faligned],inputs[:fregister])
    barr = AlignedBigArray(fregister)

    # get chunks
    params = task[:chunks][:params]
    @assert contains(task[:chunks][:kind], "chunks")
    chks = Chunks(barr, params[:origin],    params[:chksz],
                        params[:overlap],   params[:gridsz],
                        params[:voxelSize])

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
        task[:input][:inputs][:fileName] = fchk
        str_task = task2str(task)
        println("produced a new task: ")
        @show str_task
        sendSQSmessage(AWS_SQS_QUEUE_NAME, str_task)
    end
end
