using ArgParse

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--range", "-r"
            help = "the coordinate range of error regions"
            arg_type = Vector{UnitRange}
        "--origin", "-o"
            help = "the origin of chunk grids"
            arg_type = Vector{Int}
            # default = [-53,-53,-3]
            default = [257,257,33]
        "--stride", "-s"
            help = "stride of input coordinates"
            arg_type = Vector{Int}
            #default = [1024,1024,128]
            default = [896,896,112]
        "--margin", "-m"
            help = "cropping margin size"
            arg_type = Vector{Int}
            # default = [54,54,4]
            default = [64,64,8]
    end
    ret = Dict{Symbol, Any}()
    for (k,v) in parse_args(s)
        ret[Symbol(k)] = v
    end
    ret
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

function string2range(str)
    a,b = split(str, ":")
    if isempty(b)
        b = a
    end
    return parse(a):parse(b)
end 

function ArgParse.parse_item(::Type{Vector{UnitRange}}, x::AbstractString)
    x = replace(x, "[", "")
    x = replace(x, "]", "")
    map(string2range, split(x, ","))
end 

function range2blockrange(range::UnitRange, origin::Int, 
                          stride::Int, margin::Int)
    newStart = range.start - (range.start - origin) % stride
    gridSize = cld(range.stop - (newStart-1+margin), stride)
    outStart = newStart + margin
    return newStart, gridSize, outStart 
end

# main scripts
d = parse_commandline()
estimation = map(range2blockrange, 
                 d[:range], d[:origin], d[:stride], d[:margin])
origins = map(x->x[1], estimation)
gridSizes = map(x->x[2], estimation)
outStart = map(x->x[3], estimation)
# printout the results in the format for task production
println("origin: $(origins)")
println("grid sizes: $(gridSizes)")
println("output start: $(outStart)")

