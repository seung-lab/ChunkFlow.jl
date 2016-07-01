using EMIRT
using AWS
using AWS.SQS

"""
move all the s3 files to local temporal folder, and adjust the pd accordingly
Note that the omni project will not be copied, because it is output. will deal with it later.
"""
function pds32local!(pd::Dict{Symbol, Dict{Symbol, Any}})
    tmpdir = pd[:gn][:tmpdir]
    for (k,v) in pd[:gn]
        if  typeof(v)<:AbstractString && iss3(v) && k!=:outdir
            pd[:gn][k] = download( env, v, tmpdir )
        end
    end

    if typeof(pd[:znn][:fnet_spec]) <: AbstractString
        pd[:znn][:fnet_spec] = download(env, pd[:znn][:fnet_spec], tmpdir )
        pd[:znn][:fnet] = download( env, pd[:znn][:fnet], tmpdir )
    elseif typeof(pd[:znn][:fnet_spec]) <: Vector
        # multiple nets
        for idx in 1:length( pd[:znn][:fnet_spec] )
            if iss3( pd[:znn][:fnet_spec][idx] )
                pd[:znn][:fnet_spec][idx] = download(env, pd[:znn][:fnet_spec][idx], tmpdir )
            end
            if iss3( pd[:znn][:fnet][idx] )
                pd[:znn][:fnet][idx] = download( env, pd[:znn][:fnet][idx], tmpdir )
            end
        end
    else
        error("invalid fnet_spec in section [znn]!")
    end
end



"""
move the important output files to outdir
"""
function mvoutput(d::Dict{Symbol, Any})
    prjname, ext = splitext(basename(d[:fimg]))
    if iss3(d[:outdir])
        # copy local results to s3
        run(`aws s3 cp $(joinpath(d[:tmpdir],"aff.h5"))  $(joinpath(d[:outdir], "$(prjname).aff.h5")) `)
        run(`aws s3 cp $(joinpath(d[:tmpdir],"sgm.h5")) $(joinpath(d[:outdir], "$(prjname).sgm.h5"))`)
        if d[:node_switch]=="on"
            # has omni project
            run(`mv $(d[:tmpdir])aff.h5 $(d[:fomprj]).files/`)
            # the omni project path in S3
            s3fom = joinpath( d[:outdir], "$(prjname).omni")
            run(`aws s3 cp --recursive $(d[:fomprj]).files $(s3fom).files`)
            run(`aws s3 cp $(d[:fomprj]) $(s3fom)`)
        end
    elseif realpath(d[:tmpdir]) != realpath(d[:outdir]) && d[:outdir]!=""
        if realpath(dirname(d[:faff])) != realpath(dirname(d[:outdir]))
            run(`mv $(d[:faff])    $(d[:outdir])/$(prjname).aff.h5`)
        end
        if realpath(dirname(d[:fsgm])) != realpath(dirname(d[:outdir]))
            run(`mv $(d[:fsgm])   $(d[:outdir])/$(prjname).sgm.h5`)
        end
        if d[:node_switch]=="on"
            run(`mv $(d[:fomprj]) $(d[:outdir])/$(prjname).omni`)
            run(`mv $(d[:fomprj]).files $(d[:outdir])/$(prjname).omni.files`)
        end
    end
end
