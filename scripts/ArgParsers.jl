module ArgParsers

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
            help = "which device to use, negative will be cpu, 0-N will be gpu id"
            arg_type = Int
            default = -1
        "--continuefrom", "-c"
            help = "continue task submission from an start"
            arg_type = Vector{Int}
            default = Vector{Int}()
        "--task", "-t"
            help = "task definition json file location or raw json"
            arg_type = AbstractString
        "--queuename", "-q"
            help = "AWS SQS queue name. default is chunkflow-tasks"
            arg_type = AbstractString
            default = ""
        "--inputoffset", "-o"
            help = "the offset of input in whole dataset coordinate"
            arg_type = NTuple{3,Int}
        "--outputblocksize", "-s"
            help = "stride of chunks, and also the output block size"
            arg_type = NTuple{3, Int}
            default = (0,0,0)
        "--gridsize", "-g"
            help = "size of chunks grid"
            arg_type = NTuple{3, Int}
            default = (1,1,1)
        "--shutdown", "-u"
            help = "automatically shutdown this machine if no more task to do"
            arg_type = Bool
            default = false
        "--isshuffle", "-f"
            help = "whether shuffle the start list or not"
            arg_type = Bool 
            default = false
		"--inputlayer", "-i"
			help = "input neuroglancer layer path"
			arg_type = String
		"--outputlayer", "-y"
			help = "output neuroglancer layer path"
			arg_type = String
        "--masklayer", "-m"
            help = "mask the affinity map"
            arg_type = String
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

function ArgParse.parse_item(::Type{NTuple{3,Int}}, x::AbstractString)
    x = replace(x, "(", "")
    x = replace(x, ")", "")
    (map(parse, split(x, ",")) ...)
end


end # module
