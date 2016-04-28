using AWS
using AWS.SQS
#using AWS.S3
"""
build aws envariament
automatically fetch key from awscli credential file
"""
function build_env()
    # get key from aws credential file
    pd = configparser(joinpath(homedir(), ".aws/credentials"))
    env = AWSEnv(; id=pd["default"]["aws_access_key_id"], key=pd["default"]["aws_secret_access_key"], ec2_creds=false, scheme="https", region="us-east-1", ep="", sig_ver=4, timeout=0.0, dr=false, dbg=false)
    return env
end

"""
get the url of queue
"""
function get_qurl(env, qname="spipe-tasks")
    return GetQueueUrl(env; queueName=qname).obj.queueUrl
end

"""
fetch SQS message from queue url
`Inputs:`
env: AWS enviroment
qurl: String, url of queue or queue name
"""
function fetchSQSmessage(env, qurl)
    if !contains(qurl, "https://sqs.")
        # this is not a url, should be a queue name
        qurl = get_qurl(env, qurl)
    end
    resp = ReceiveMessage(env, queueUrl = qurl)
    msg = resp.obj.messageSet[1]
    return msg
end

"""
take SQS message from queue
will delete mssage after fetching
"""
function takeSQSmessage!(env, qurl="")
    if !contains(qurl, "https://sqs.")
        # this is not a url, should be a queue name
        qurl = get_qurl(env, qurl)
    end

    msg = fetchSQSmessage(env, qurl)
    # delete the message in queue
    resp = DeleteMessage(env, queueUrl=qurl, receiptHandle=msg.receiptHandle)
    # resp = DeleteMessage(env, msg)
    if resp.http_code < 299
        println("message deleted")
    else
        println("message taking failed!")
    end
    return msg
end


"""
whether this file is in s3
"""
function iss3(fname)
    return ismatch(r"^(s3://)", fname)
end

"""
transfer s3 file to local and return local file name
`Inputs:`
env: AWS enviroment
s3name: String, s3 file path
lcname: String, local temporal folder path or local file name

`Outputs:`
lcname: String, local file name
"""
function s32local(env::AWSEnv, s3name::AbstractString, tmpdir::AbstractString)
    # directly return if not s3 file
    if !iss3(s3name)
        return s3name
    end

    @assert isdir(tmpdir)
    # get the file name

    dir, fname = splitdir(s3name)
    dir = replace(dir, "s3://", "")
    # local directory
    lcdir = joinpath(tmpdir, dir)
    # local file name
    lcfname = joinpath(lcdir, fname)
    # remove existing file
    if isfile(lcfname)
        rm(lcfname)
    else
        # create local directory
        mkpath(lcdir)
    end
    # download s3 file using awscli
    run(`aws s3 cp $(s3name) $(lcfname)`)
    return lcfname
end

"""
move all the s3 files to local temporal folder, and adjust the pd accordingly
Note that the omni project will not be copied, because it is output. will deal with it later.
"""
function pds32local!(env::AWSEnv, pd::Dict)
    tmpdir = pd["gn"]["tmpdir"]
    if iss3(pd["gn"]["fimg"])
        pd["gn"]["fimg"] = s32local( env, pd["gn"]["fimg"], tmpdir )
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
        run(`aws s3 cp --recursive $(d["tmpdir"])/aff.h5 $(d["outdir"])/aff.h5`)
        run(`aws s3 cp --recursive $(d["tmpdir"])/segm.h5 $(d["outdir"])/segm.h5`)
        run(`aws s3 cp --recursive $(d["tmpdir"])/$(pd["omni"]["fomprj"]).omni.files $(d["outdir"])/$(pd["omni"]["fomprj"]).omni.files`)
        run(`aws s3 cp --recursive $(d["tmpdir"])/$(pd["omni"]["fomprj"]).omni $(d["outdir"])/$(pd["omni"]["fomprj"]).omni`)
    elseif realpath(d["tmpdir"]) != realpath(d["outdir"]) && d["outdir"]!=""
        run(`mv $(d["faff"])    $(d["outdir"])/`)
        run(`mv $(d["fsegm"])   $(d["outdir"])/`)
        run(`mv $(d["fomprj"])* $(d["outdir"])/`)
    end
end
