using Agglomerator
using Process
using EMIRT
using HDF5
include("aff2segm.jl")
include("segm2omprj.jl")
include("zforward.jl")
include("aws.jl")
include("config.jl")

const env = build_env()

# the task information was embedded in a dictionary
pd = get_task(env)

# copy data from s3 to local temp directory
pds32local!(env, pd)

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
        # aff = aff2uniform(aff)
        # seg, dend, dendValues = aff2segm(aff, pd["ws"]["low"], pd["ws"]["high"])
        low  = rthd2athd(aff, pd["ws"]["low"])
        high = rthd2athd(aff, pd["ws"]["high"])
        seg, dend, dendValues = aff2segm(aff, low, high)
    else
        seg, dend, dendValues = aff2segm(aff, pd["ws"]["low"], pd["ws"]["high"])
    end

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
