using EMIRT
using Agglomeration
using Process

export segm2omprj

function segm2omprj(d::Dict{AbstractString, Any})
    if contains(d["node_switch"], "off")
        return
    end
    println("start omnification...")
    segm2omprj(d["ombin"], d["fimg"], d["fsegm"], d["voxel_size"], d["offset"], d["fomprj"])
end

function segm2omprj(ombin, fimg, fsegm, vs=[4,4,40], offset = [0,0,0], fomprj="/tmp/tmp.omni")
    fimgh5 = fimg
    if contains(fimg, ".tif")
        # transform tif image to hdf5
        img = imread(fimg)
        fimgh5 = replace(fimg, ".tiff", ".h5")
        fimgh5 = replace(fimg, ".tif", ".h5")
        if isfile(fimgh5)
            rm(fimgh5)
        end
        imsave(img, fimgh5)
    end
    # compute physical offset
    phyOffset = offset .* vs

    # prepare the cmd file for omnification
    # make omnify command file
    cmd = """create:$(fomprj)
    loadHDF5chann:$(fimgh5)
    setChanResolution:1,$(vs[1]),$(vs[2]),$(vs[3])
    setChanAbsOffset:,1,$(phyOffset[1]),$(phyOffset[2]),$(phyOffset[3])
    loadHDF5seg:$(fsegm)
    setSegResolution:1,$(vs[1]),$(vs[2]),$(vs[3])
    setSegAbsOffset:1,$(phyOffset[1]),$(phyOffset[2]),$(phyOffset[3])
    mesh
    quit
    """
    # write the cmd file
    f = open("/tmp/omnify.cmd", "w")
    write(f, cmd)
    close(f)

    # run omnifycation
    run(`$(ombin) --headless --cmdfile='/tmp/omnify.cmd'`)
end
