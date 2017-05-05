using ArgParse

export parse_commandline

"""
    key2symbol(argDict::Dict{String, Any})

make the key to be type of symbol
"""
function key2symbol(argDict::Dict)
    ret = Dict{Symbol, Any}()
    for (k,v) in argDict
        ret[Symbol(k)] = v
    end
    ret
end

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--deviceid", "-d"
            help = "which gpu to use"
            arg_type = Int
        "--workernumber", "-n"
            help = "number of works"
            arg_type = Int
            default = 1
        "--workerwaittime", "-w"
            help = "waiting time to launch each worker (min)"
            arg_type = Int
            default = 1
        "--continuefrom", "-c"
            help = "continue task submission from an origin"
            arg_type = Vector{Int}
            default = Vector{Int}()
        "--task", "-t"
            help = "task definition json file"
            arg_type = AbstractString
        "--queuename", "-q"
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
        "--shutdown", "-u"
            help = "automatically shutdown this machine if no more task to do"
            arg_type = Bool
            default = false
    end
    return key2symbol( parse_args(s) )
end

"""
ArgParse do not support parsing vector
customized parsing type.
http://argparsejl.readthedocs.io/en/latest/argparse.html#parsing-to-custom-types
"""
function ArgParse.parse_item(::Type{Vector{Int}}, x::AbstractString)
    x = replace(x, "[", "")
    x = replace(x, "]", "")
    map(parse, split(x, ","))
end
