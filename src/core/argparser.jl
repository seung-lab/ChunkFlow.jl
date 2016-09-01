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
    end
    return parse_args(s)
end
