using EMIRT

include("aff2segm.jl")
include("segm2omprj.jl")
include("zforward.jl")
include("aws.jl")

const global env = build_env()
const global queuename = "spipe-tasks"

function main()
    is_auto_shutdown = false
    # keep doing tasks
    while true
        try
            # the task information was embedded in a dictionary
            pd = get_task(env)
            is_auto_shutdown = pd["gn"]["is_auto_shutdown"]
            # do this task
            handletask(pd)
        catch
            # auto shutdown
            if is_auto_shutdown
                run(`sudo shutdown -h 0`)
            else
                error("no task to do!")
            end
        end
    end
end

"""
handle a task
"""
function handletask( pd::Dict{AbstractString, Dict{AbstractString, Any}} )
    println("start doing a task...")
    @show pd
    # znn forward pass to get affinity map
    # file name to save affinity map
    zforward( pd["znn"] )

    # watershed and aggromeration
    aff2segm(pd["ws"])

    # omnification
    segm2omprj(pd["omni"])

    # move results
    mvoutput(pd["gn"])
end


# run the main function
main()
