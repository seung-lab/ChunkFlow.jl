using ArgParse

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--deviceid", "-d"
            help = "which gpu to use"
            arg_type = Int
        "--task", "-t"
            help = "task definition json file"
            arg_type = AbstractString
        "--awssqs", "-a"
            help = "AWS SQS queue name. default is chunkflow-tasks"
            arg_type = AbstractString
            default = "chunkflow-tasks"
        "--origin", "-o"
            help = "the origin of chunk grids"
            arg_type = Vector{Int}
        "--stride", "-s"
            help = "stride of chunks"
            arg_type = Vector{Int}
            default = [0,0,0]
        "--gridsize", "-g"
            help = "size of chunks grid"
            arg_type = Vector{Int}
            default = [1,1,1]
    end
    return parse_args(s)
end

"""
ArgParse do not support parsing vector
customized parsing type.
http://argparsejl.readthedocs.io/en/latest/argparse.html#parsing-to-custom-types
"""
function ArgParse.parse_item(::Type{Vector{Int}}, x::AbstractString)
    ret = Vector{Int}()
    x = replace(x, "[", "")
    x = replace(x, "]", "")
    x = replace(x, " ", "")
    for i in split(x, ',')
        push!(ret, parse(Int, i))
    end
    return ret
end
