using Agglomerator
using Process
using EMIRT
using HDF5
include("affs2segm.jl")
include("segm2omprj.jl")
include("zforward.jl")
include("aws.jl")

"""
get spipe parameters
"""
env = build_env()
function get_task(env::AWSEnv)
    # parse the config file
    if length(ARGS)==0
        msg = takeSQSmessage!(env,"spipe-tasks")
        conf = msg.body
        conf = replace(conf, "\\n", "\n")
        conf = replace(conf, "\"", "")
        conf = split(conf, "\n")
        conf = Vector{ASCIIString}(conf)
    elseif length(ARGS)==1
        fconf = ARGS[1]
        conf = readlines(fconf)
    else
        error("too many commandline arguments")
    end
    return configparser(conf)
end

"""
move all the s3 files to local temporal folder, and adjust the pd accordingly
Note that the omni project will not be copied, because it is output. will deal with it later.
"""
function s32local!(env::AWSEnv, pd::Dict)
    tmpdir = pd["gn"]["tmp_dir"]
    if iss3(pd["gn"]["fimg"])
        pd["gn"]["fimg"] = s32local( env, pd["gn"]["fimg"], tmpdir )
    end

    if typeof( pd["znn"]["fnet_specs"] ) <: AbstractString
        pd["znn"]["fnet_specs"] = s32local(env, pd["znn"]["fnet_specs"], tmpdir )
        pd["znn"]["fnets"] = s32local( env, pd["znn"]["fnets"], tmpdir )
    else
        # multiple nets
        for idx in 1:length( pd["znn"]["fnet_specs"] )
            if iss3( pd["znn"]["fnet_specs"][idx] )
                pd["znn"]["fnet_specs"][idx] = s32local(env, pd["znn"]["fnet_specs"][idx], tmpdir )
            end
            if iss3( pd["znn"]["fnets"][idx] )
                pd["znn"]["fnets"][idx] = s32local( env, pd["znn"]["fnets"][idx], tmpdir )
            end
        end
    end
end

"""
clear a floder
"""
function cleardir(dir::AbstractString)
    for fname in readdir(dir)
        rm(joinpath(dir, fname), recursive=true)
    end
end
# clear the temporal folder
#cleardir(pd["gn"]["tmp_dir"])

# the task information was embedded in a dictionary
pd = get_task(env)

# copy data from s3 to local temp directory
@show pd
s32local!(env, pd)

# get affinity map
faffs = pd["gn"]["faffs"]
if pd["znn"]["is_znn"]
    if !isfile(faffs) || pd["znn"]["is_overwrite"]
        println("run forward path to create one...")
        if isfile(faffs) && pd["znn"]["is_overwrite"]
            rm(faffs)
        end
        zforward(faffs, pd["gn"]["tmp_dir"], pd["gn"]["fimg"], pd["znn"]["dir"], pd["znn"]["fnet_specs"][1], pd["znn"]["fnets"][1], pd["znn"]["outszs"][1:3], pd["znn"]["fnet_specs"][2], pd["znn"]["fnets"][2], pd["znn"]["outszs"][4:6], pd["znn"]["is_stdio"])
    end
end

# watershed, affs to segm
if pd["ws"]["is_watershed"]
    # read affinity map
    print("reading affinity map...")
    affs = h5read(pd["gn"]["faffs"], "/main")
    println("done!")

    # watershed
    # exchange x and z channel
    if pd["ws"]["is_exchange_affs_xz"]
        exchangeaffsxz!(affs)
    end
    # remap to uniform distribution
    if pd["ws"]["is_remap"]
        affs = affs2uniform(affs)
    end

    seg, dend, dendValues = affs2segm(affs, pd["ws"]["low"], pd["ws"]["high"])

    # aggromeration
    if pd["agg"]["is_agg"]
        dend, dendValues = Process.forward(affs, seg)
    end
    # save seg and mst
    save_segm(pd["gn"]["fsegm"], seg, dend, dendValues)
end

# omnification
if pd["omni"]["is_omni"]
    fomprj = joinpath(pd["gn"]["tmp_dir"], "tmp.omni")
    segm2omprj(pd["omni"]["ombin"], pd["gn"]["fimg"], pd["gn"]["fsegm"], pd["gn"]["voxel_size"], fomprj)
end

if iss3(pd["gn"]["outdir"])
    # copy local results to s3
    run(`aws s3 sync $(pd["gn"]["tmp_dir"]) $(pd["gn"]["outdir"])`)
else
    #mv()
end

# auto shutdown
if pd["gn"]["is_auto_shutdown"]
    run(`sudo shutdown -h 0`)
end
