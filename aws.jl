using EMIRT
using AWS

"""
move all the s3 files to local temporal folder, and adjust the pd accordingly
Note that the omni project will not be copied, because it is output. will deal with it later.
"""
function pds32local!(env::AWSEnv, pd::Dict)
    tmpdir = pd["gn"]["tmpdir"]
    for (k,v) in pd["gn"]
        if typeof(v)<:AbstractString && iss3(v) && k!="outdir"
            pd["gn"][k] = s32local( env, v, tmpdir )
        end
    end

    if typeof( pd["znn"]["fnet_spec"] ) <: AbstractString
        pd["znn"]["fnet_spec"] = s32local(env, pd["znn"]["fnet_spec"], tmpdir )
        pd["znn"]["fnet"] = s32local( env, pd["znn"]["fnet"], tmpdir )
    else
        # multiple nets
        for idx in 1:length( pd["znn"]["fnet_spec"] )
            if iss3( pd["znn"]["fnet_spec"][idx] )
                pd["znn"]["fnet_spec"][idx] = s32local(env, pd["znn"]["fnet_spec"][idx], tmpdir )
            end
            if iss3( pd["znn"]["fnet"][idx] )
                pd["znn"]["fnet"][idx] = s32local( env, pd["znn"]["fnet"][idx], tmpdir )
            end
        end
    end
end


"""
get spipe parameters
"""
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
            lcfile = s32local(env, ARGS[1], "/tmp/")
            conf = readlines( lcfile )
        else
            conf = readlines( ARGS[1] )
        end
    else
        error("too many commandline arguments")
    end
    pd = configparser(conf)
    # make default parameters
    if pd["omni"]["fomprj"]==""
        fimg = basename(pd["gn"]["fimg"])
        name, ext = splitext(fimg)
        pd["omni"]["fomprj"] = joinpath(pd["gn"]["tmpdir"], "$name.omni")
    end
    # copy data from s3 to local temp directory
    pds32local!(env, pd)

    # share the general parameters in other sections
    pd = shareprms!(pd, "gn")
    @show pd
    return pd
end

"""
move the important output files to outdir
"""
function mvoutput(d::Dict{AbstractString, Any})
    if iss3(d["outdir"])
        # copy local results to s3
        run(`aws s3 cp $(d["tmpdir"])/aff.h5 $(d["outdir"])/aff.h5`)
        run(`aws s3 cp $(d["tmpdir"])/segm.h5 $(d["outdir"])/segm.h5`)
        run(`aws s3 cp --recursive $(d["tmpdir"])/$(pd["omni"]["fomprj"]).omni.files $(d["outdir"])/$(pd["omni"]["fomprj"]).omni.files`)
        run(`aws s3 cp $(d["tmpdir"])/$(pd["omni"]["fomprj"]).omni $(d["outdir"])/$(pd["omni"]["fomprj"]).omni`)
    elseif realpath(d["tmpdir"]) != realpath(d["outdir"]) && d["outdir"]!=""
        run(`mv $(d["faff"])    $(d["outdir"])/`)
        run(`mv $(d["fsegm"])   $(d["outdir"])/`)
        run(`mv $(d["fomprj"])* $(d["outdir"])/`)
    end
end
