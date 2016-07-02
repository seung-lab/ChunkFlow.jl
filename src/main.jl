using EMIRT

include("core/aff2sgm.jl")
include("core/sgm2omprj.jl")
include("core/img2aff.jl")
include("core/aws.jl")
include("core/task.jl")
include(joinpath(Pkg.dir(), "EMIRT/src/plugins/aws.jl"))

const global env = build_env()
const global queuename = "spipe-tasks"

function main()
    if length(ARGS)>0
        # the task information was embedded in a dictionary
        pd = get_task(env)
        # do this task
        handletask(pd)
    else
        # keep fetching tasks from AWS SQS, and keep busy doing tasks
        while true
            is_auto_shutdown = false
            try
                # the task information was embedded in a dictionary
                pd = get_task()
                # update the status of auto shutdown
                is_auto_shutdown = pd["gn"]["is_auto_shutdown"]
                # do this task
                handletask(pd)
                # avoid endless loop for local use
                if length(ARGS) > 0
                    if is_auto_shutdown
                        run(`sudo shutdown -h 0`)
                    else
                        break
                    end
                end
            catch
                # auto shutdown
                if is_auto_shutdown
                    run(`sudo shutdown -h 0`)
                else
                    backtrace()
                    error("no task to do!")
                end
            end
        end
    end
end

"""
handle a task
"""
function handletask( pd::Tpd )
    println("start doing a task...")
    # znn forward pass to get affinity map
    # file name to save affinity map
    img2aff( pd[:znn] )

    # watershed and aggromeration
    aff2sgm(pd[:ws])

    # omnification
    sgm2omprj(pd[:omni])

    # move results
    mvoutput(pd[:omni])
end

# run the main function
main()
