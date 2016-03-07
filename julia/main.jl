using EMIRT
using HDF5
include("affs2segm.jl")
include("segm2omprj.jl")

function default_params!(pd)
    tmp_dir = pd["gn"]["tmp_dir"]
    if pd["gn"]["faffs"]==""
        pd["gn"]["faffs"] = tmp_dir * "/out_sample10_output_0.tif"
    end
end

# parse the config file
fconf = "params.cfg"
pd = configparser(fconf)

# watershed, affs to segm
# read affinity map
affs = h5read(pd["gn"]["faffs"], "/main")

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
