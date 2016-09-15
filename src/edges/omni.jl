
"""
edge function of omnification
"""
function ef_omnification( c::DictChannel,
                params::OrderedDict{Symbol, Any},
                inputs::OrderedDict{Symbol, Any},
                outputs::OrderedDict{Symbol, Any})
    # prepare uncompressed files
    chk_img = fetch(c, inputs[:img])
    fimg = string(tempname(),".img.h5")
    if isfile(fimg)
        rm(fimg)
    end
    h5write(fimg, "main", chk_img.data)

    chk_sgm = fetch(c, inputs[:sgm])
    fsgm = string(tempname(), ".sgm.h5")
    # prepare input files
    # note that omni do not support compression and chunked hdf5
    if isfile(fsgm)
        rm(fsgm)
    end
    h5write(fsgm, "main", chk_sgm.data.segmentation)
    h5write(fsgm, "dend", chk_sgm.data.segmentPairs)
    h5write(fsgm, "dendValues", chk_sgm.data.segmentPairAffinities)

    # the origin and end of this chunk
    origin = chk_sgm.origin
    volend = origin .+ [size(chk_sgm.data.segmentation)...] - 1

    # assign auto project name
    omniProjectDir = tempname()
    mkdir(omniProjectDir)
    omniProjectName = joinpath(omniProjectDir,
        "$(basename(outputs[:prefix]))$(origin[1]-1)-$(volend[1]-1)_$(origin[2]-1)-$(volend[2]-1)_$(origin[3]-1)-$(volend[3]-1).omni")

    # compute physical offset
    phyOffset = physical_offset(chk_img)
    # voxel size
    vs = chk_sgm.voxelSize

    # prepare the cmd file for omnification
    # make omnify command file
    cmd = """create:$(omniProjectName)
    loadHDF5chann:$(fimg)
    setChanResolution:1,$(vs[1]),$(vs[2]),$(vs[3])
    setChanAbsOffset:1,$(phyOffset[1]),$(phyOffset[2]),$(phyOffset[3])
    loadHDF5seg:$(fsgm)
    setSegResolution:1,$(vs[1]),$(vs[2]),$(vs[3])
    setSegAbsOffset:1,$(phyOffset[1]),$(phyOffset[2]),$(phyOffset[3])
    """
    # add meshing or not
    if params[:isMeshing]
      cmd = string(cmd, "mesh\nquit\n")
    else
      cmd = string(cmd, "quit\n")
    end
    @show cmd
    # write the cmd file
    fcmd = string(tempname(),".omnify.cmd")
    f = open(fcmd, "w")
    write(f, cmd)
    close(f)

    # use tcmalloc to accelerate meshing. another alternative is jemalloc
    #run(`export LD_PRELOAD=/usr/lib/libtcmalloc_minimal.so.4`)
    # run omnifycation
    run(`$(params[:ombin]) --headless --cmdfile=$(fcmd)`)
    rm(fsgm); rm(fimg); rm(fcmd)

    # move omni project
    prefix = replace(outputs[:prefix],"~",homedir())
    if iss3(prefix) || isGoogleStorage(prefix)
      upload( omniProjectName, dirname(prefix) )
    else
      mv(omniProjectName, joinpath(dirname(prefix), basename(omniProjectName)))
      mv("$(omniProjectName).files", joinpath(dirname(prefix), "$(basename(omniProjectName)).files"))
    end
end
