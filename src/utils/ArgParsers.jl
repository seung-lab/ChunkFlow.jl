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
        "--device-id", "-d"
            help = "which device to use, negative will be cpu, 0-N will be gpu id"
            arg_type = Int
            default = -1
        "--continue-from", "-c"
            help = "continue task submission from an output start"
            arg_type = Vector 
            default = Vector()
        "--queuename", "-q"
            help = "AWS SQS queue name. default is chunkflow-tasks"
            arg_type = AbstractString
            default = ""
        "--output-start", "-o"
            help = "the origin of chunk grids"
            arg_type = NTuple{3,Int}
        "--chunk-size", "-k"
            help = "cutout image chunk size"
            arg_type = NTuple{3, Int}
            default = (1074, 1074, 144)
        "--stride", "-s"
            help = "stride of chunks"
            arg_type = NTuple{3, Int}
            default = (0,0,0)
        "--gridsize", "-g"
            help = "size of chunks grid"
            arg_type = NTuple{3, Int}
            default = (1,1,1)
        "--is-shuffle", "-f"
            help = "whether shuffle the start list or not"
            arg_type = Bool 
            default = false
		"--input-layer", "-i"
			help = "input neuroglancer layer path"
			arg_type = String
		"--output-layer", "-y"
			help = "output neuroglancer layer path"
			arg_type = String
        "--mask-layer", "-m"
            help = "mask the affinity map"
            arg_type = String
        "--convnet-file", "-v"
            help = "convnet file path"
            arg_type = String
            default = "/import/convnet"
        "--patch-overlap", "-p"
            help = "voxel overlap of patches (x,y,z)"
            arg_type = NTuple{3, Int} 
            default = (64, 64, 4)
    end
    return key2symbol( parse_args(s) )
end

"""
ArgParse do not support parsing vector
customized parsing type.
http://argparsejl.readthedocs.io/en/latest/argparse.html#parsing-to-custom-types
"""
function ArgParse.parse_item(::Type{Vector}, x::AbstractString)
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
