include("aws.jl")

"""
get spipe parameters
"""
function get_task(queuename::ASCIIString = "spipe-tasks")
    return get_task(env, queuename)
end
function get_task(env::AWSEnv, queuename::ASCIIString = "spipe-tasks")
    # parse the config file
    if length(ARGS)==0
        msg = takeSQSmessage!(env, queuename)
        conf = msg.body
        conf = replace(conf, "\\n", "\n")
        conf = replace(conf, "\"", "")
        conf = split(conf, "\n")
        conf = Vector{ASCIIString}(conf)
    elseif length(ARGS)==1
        if iss3( ARGS[1] )
            lcfile = download(env, ARGS[1], "/tmp/")
            conf = readlines( lcfile )
        else
            conf = readlines( ARGS[1] )
        end
    else
        error("too many commandline arguments")
    end
    pd = configparser(conf)
    # copy data from s3 to local temp directory
    pds32local!(pd)

    # preprocessing the parameter dict
    # eg. add some default values
    pd = preprocess!(pd)

    @show pd
    return pd
end

function fname2offset(fname::AbstractString)
    # initialize the offset
    offset = Vector{Int64}()

    bn = basename(fname)
    name, ext = splitext(bn)
    # substring list
    strlst = split(name, "_")
    for str in strlst
        if contains(str, "-")
            strlst2 = split(str, "-")
            if typeof(parse(strlst2[1]))<:Int64
                push!(offset, parse(strlst2[1]))
            end
        end
    end
    if length(offset)==3
        return offset
    else
        warn("invalid auto offset, use default [0,0,0]!")
        return nothing
    end
end

"""
preprocess the parameter dictionary
- set default parameters
- auto correct some parameters

`Inputs`:
- pd: parameter dict

`Outputs`:
- updated parameter dict
"""
function preprocess!(pd::Tpd)
    # make default parameters
    if pd[:omni][:fomprj]==nothing
        bn = basename(pd[:gn][:fimg])
        name, ext = splitext(bn)
        pd[:omni][:fomprj] = joinpath(pd[:gn][:tmpdir], "$(name).omni")
    end

    # default offset from image filename
    if pd[:gn][:offset]==nothing
        pd[:gn][:offset] = [0,0,0]
    end
    offset = fname2offset(pd[:gn][:fimg])
    if pd[:gn][:offset]==[0,0,0] && offset!=nothing
        pd[:gn][:offset] = offset
    end

    # share the general parameters in other sections
    pd = shareprms!(pd, :gn)
    return pd
end
