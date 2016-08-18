
"""
edge function of omnification
"""
function ef_omnification( c::DictChannel,
                params::OrderedDict{Symbol, Any},
                inputs::OrderedDict{Symbol, Any},
                outputs::OrderedDict{Symbol, Any})
    # prepare uncompressed files
    fimg = inputs[:fimg]
    chk_img = readchk(fimg)
    fimg = "/tmp/img.h5"
    if isfile(fimg)
        rm(fimg)
    end
    h5write(fimg, "main", chk_img.data)

    fsgm = inputs[:fsgm]
    chk_sgm = readchk(fsgm)
    fsgm = "/tmp/sgm.h5"
    # prepare input files
    # note that omni do not support compression and chunked hdf5
    if isfile(fsgm)
        rm(fsgm)
    end
    h5write(fsgm, "main", chk_sgm.seg)
    h5write(fsgm, "dend", chk_sgm.dend)
    h5write(fsgm, "dendValues", chk_sgm.dendValues)

    # assign auto project name
    fprj = outputs[:fprj]
    origin = chk_sgm.origin
    volend = origin .+ [size(chk_sgm.data)...] - 1
    if isdir(fprj)
        fprj = joinpath(fprj, "chunk_$(origin[1])-$(volend[1])_$(origin[2])-$(volend[2])_$(origin[3])-$(volend[3]).omni")
    elseif !contains(fprj, ".omni")
        # assume that it is an prefix
        fprj = string(fprj, "$(origin[1])-$(volend[1])_$(origin[2])-$(volend[2])_$(origin[3])-$(volend[3]).omni")
    end


    # compute physical offset
    phyOffset = physical_offset(chk_sgm)
    # voxel size
    vs = chk_sgm.voxelsize

    # prepare the cmd file for omnification
    # make omnify command file
    cmd = """create:$(fprj)
    loadHDF5chann:$(fimg)
    setChanResolution:1,$(vs[1]),$(vs[2]),$(vs[3])
    setChanAbsOffset:1,$(phyOffset[1]),$(phyOffset[2]),$(phyOffset[3])
    loadHDF5seg:$(fsgm)
    setSegResolution:1,$(vs[1]),$(vs[2]),$(vs[3])
    setSegAbsOffset:1,$(phyOffset[1]),$(phyOffset[2]),$(phyOffset[3])
    mesh
    quit
    """
    # write the cmd file
    fcmd = "/tmp/omnify.cmd"
    f = open(fcmd, "w")
    write(f, cmd)
    close(f)

    # use tcmalloc to accelerate meshing. another alternative is jemalloc
    #run(`export LD_PRELOAD=/usr/lib/libtcmalloc_minimal.so.4`)
    # run omnifycation
    run(`$(params[:ombin]) --headless --cmdfile=$(fcmd)`)
end
