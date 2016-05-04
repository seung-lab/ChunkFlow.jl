using EMIRT
using AWS
using AWS.SQS

"""
move all the s3 files to local temporal folder, and adjust the pd accordingly
Note that the omni project will not be copied, because it is output. will deal with it later.
"""
function pds32local!(pd::Dict)
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
move the important output files to outdir
"""
function mvoutput(d::Dict{AbstractString, Any})
    if iss3(d["outdir"])
        # copy local results to s3
        run(`aws s3 cp $(d["tmpdir"])/aff.h5 $(d["outdir"])/aff.h5`)
        run(`aws s3 cp $(d["tmpdir"])/segm.h5 $(d["outdir"])/segm.h5`)
        run(`aws s3 cp --recursive $(d["tmpdir"])/$(d["fomprj"]).omni.files $(d["outdir"])/$(d["fomprj"]).omni.files`)
        run(`aws s3 cp $(d["tmpdir"])/$(d["fomprj"]).omni $(d["outdir"])/$(d["fomprj"]).omni`)
    elseif realpath(d["tmpdir"]) != realpath(d["outdir"]) && d["outdir"]!=""
        run(`mv $(d["faff"])    $(d["outdir"])/`)
        run(`mv $(d["fsegm"])   $(d["outdir"])/`)
        run(`mv $(d["fomprj"])* $(d["outdir"])/`)
    end
end
