using ArgParse

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--gpuid", "-g"
            help = "which gpu to use"
            arg_type = Int
        "--task", "-t"
            help = "task definition json file"
            arg_type = AbstractString
        "--awssqs", "-s"
            help = "AWS SQS queue name. default is chunkflow-tasks"
            arg_type = AbstractString
            default = "chunkflow-tasks"
    end
    return parse_args(s)
end
