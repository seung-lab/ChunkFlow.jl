export get_task

include("aws.jl")

"""
get spipe parameters
"""
function get_task(env::AWSEnv)
    # parse the config file
    if length(ARGS)==0
        msg = takeSQSmessage!(env,"spipe-tasks")
        conf = msg.body
        conf = replace(conf, "\\n", "\n")
        conf = replace(conf, "\"", "")
        conf = split(conf, "\n")
        conf = Vector{ASCIIString}(conf)
    elseif length(ARGS)==1
        fconf = ARGS[1]
        conf = readlines(fconf)
    else
        error("too many commandline arguments")
    end
    return configparser(conf)
end
