using EMIRT
using HDF5
include("affs2segm.jl")
include("segm2omprj.jl")
include("zforward.jl")

# parse the config file
fconf = "params.cfg"
pd = configparser(fconf)

# get affinity map
faffs = pd["gn"]["faffs"]
if !isfile(faffs) || pd["znn"]["is_overwrite"]
    println("run forward path to create one...")
    if isfile(faffs) && pd["znn"]["is_overwrite"]
        rm(faffs)
    end
    zforward(faffs, pd["gn"]["tmp_dir"], pd["gn"]["fimg"], pd["znn"]["dir"], pd["znn"]["fnet_specs"][1], pd["znn"]["fnets"][1], pd["znn"]["outszs"][1:3], pd["znn"]["fnet_specs"][2], pd["znn"]["fnets"][2], pd["znn"]["outszs"][4:6], pd["znn"]["is_stdio"])
end

# read affinity map
println("reading affinity map...")
affs = h5read(faffs, "/main")

# watershed, affs to segm

# watershed
# exchange x and z channel
if pd["ws"]["is_exchange_affs_xz"]
    exchangeaffsxz!(affs)
end
# remap to uniform distribution
if pd["ws"]["is_remap"]
    affs2uniform!(affs)
end

seg, dend, dendValues = affs2segm(affs, pd["ws"]["low"], pd["ws"]["high"])
# save seg and mst
save_segm(pd["gn"]["fsegm"], seg, dend, dendValues)

# omnification
segm2omprj(pd["omni"]["ombin"], pd["gn"]["fimg"], pd["gn"]["fsegm"], pd["gn"]["voxel_size"], pd["omni"]["fomprj"])
