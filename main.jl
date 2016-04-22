using Agglomerator
using Process
using EMIRT
using HDF5
include("aff2segm.jl")
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
s32local!(env, pd)

# share the general parameters in other sections
pd = shareprms!(pd, "gn")
@show pd

# znn forward pass to get affinity map
# file name to save affinity map
faff = pd["gn"]["faff"]
if pd["znn"]["is_znn"]
    if !isfile(faff) || pd["znn"]["is_overwrite"]
        println("run forward path to create one...")
        if isfile(faff) && pd["znn"]["is_overwrite"]
            rm(faff)
        end
        inps = Dict( "img"=> pd["gn"]["fimg"] )
        outs = zforward(pd["znn"], inps)
    end
end

# watershed, aff to segm
if pd["ws"]["is_watershed"]
    # read affinity map
    print("reading affinity map...")
    aff = h5read(pd["gn"]["faff"], "/main")
    println("done!")

    # watershed
    # exchange x and z channel
    if pd["ws"]["is_exchange_aff_xz"]
        exchangeaffxz!(aff)
    end
    # remap to uniform distribution
    if pd["ws"]["is_remap"]
        aff = aff2uniform(aff)
    end

    seg, dend, dendValues = aff2segm(aff, pd["ws"]["low"], pd["ws"]["high"])

    # aggromeration
    if pd["agg"]["is_agg"]
        dend, dendValues = Process.forward(aff, seg)
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
