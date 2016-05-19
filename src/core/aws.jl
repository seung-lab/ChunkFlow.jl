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
            pd["gn"][k] = download( env, v, tmpdir )
        end
    end

    if typeof( pd["znn"]["fnet_spec"] ) <: AbstractString
        pd["znn"]["fnet_spec"] = download(env, pd["znn"]["fnet_spec"], tmpdir )
        pd["znn"]["fnet"] = download( env, pd["znn"]["fnet"], tmpdir )
    else
        # multiple nets
        for idx in 1:length( pd["znn"]["fnet_spec"] )
            if iss3( pd["znn"]["fnet_spec"][idx] )
                pd["znn"]["fnet_spec"][idx] = download(env, pd["znn"]["fnet_spec"][idx], tmpdir )
            end
            if iss3( pd["znn"]["fnet"][idx] )
                pd["znn"]["fnet"][idx] = download( env, pd["znn"]["fnet"][idx], tmpdir )
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
        if d["node_switch"]=="off"
            # no omnification, only copy affinity map and segmentation
            run(`aws s3 cp $(joinpath(d["tmpdir"],"aff.h5"))  $(joinpath(d["outdir"], "aff.h5")) `)
            run(`aws s3 cp $(joinpath(d["tmpdir"],"segm.h5")) $(joinpath(d["outdir"], "segm.h5"))`)
        else
            # has omni project
            run(`mv $(d["tmpdir"])aff.h5 $(d["fomprj"]).files/`)
            # the omni project path in S3
            s3fom = joinpath( d["outdir"], basename(d["fomprj"]))
            run(`aws s3 cp --recursive $(d["fomprj"]).files $(s3fom).files`)
            run(`aws s3 cp $(d["fomprj"]) $(s3fom)`)
        end
    elseif realpath(d["tmpdir"]) != realpath(d["outdir"]) && d["outdir"]!=""
        if realpath(dirname(d["faff"])) != realpath(dirname(d["outdir"]))
            run(`mv $(d["faff"])    $(d["outdir"])/`)
        end
        if realpath(dirname(d["fsegm"])) != realpath(dirname(d["outdir"]))
            run(`mv $(d["fsegm"])   $(d["outdir"])/`)
        end
        if d["node_switch"]=="on"
            run(`mv $(d["fomprj"])* $(d["outdir"])/`)
        end
    end
end
