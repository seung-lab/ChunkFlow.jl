

export ef_omnification

"""
edge function of omnification
"""
function ef_omnification( c::DictChannel, e::Edge)
    chk_img = fetch(c, e.inputs[:img])
    chk_sgm = fetch(c, e.inputs[:sgm])
    img = chk_img.data
    sgm = chk_sgm.data
    @assert isa(img, Timg)
    @assert isa(sgm, Tsgm)

    # assign auto project name
    fprj = e.outputs[:fprj]
    origin = chk_img.origin
    volend = origin .+ [size(chk_img.data)...] - 1
    if isdir(fprj)
        fprj = joinpath(fprj, "chunk_$(origin[1])-$(volend[1])_$(origin[2])-$(volend[2])_$(origin[3])-$(volend[3]).omni")
    elseif !contains(fprj, ".omni")
        # assume that it is an prefix
        fprj = string(fprj, "_$(origin[1])-$(volend[1])_$(origin[2])-$(volend[2])_$(origin[3])-$(volend[3]).omni")
    end

    # prepare input files
    fimg = "/tmp/img.h5"
    fsgm = "/tmp/sgm.h5"
    fcmd = "/tmp/omnify.cmd"
    saveimg(fimg, img, "main")
    savesgm(fsgm, sgm)
    # compute physical offset
    phyOffset = physical_offset(chk_img)
    # voxel size
    vs = chk_img.voxelsize

    # prepare the cmd file for omnification
    # make omnify command file
    cmd = """create:$(fprj)
    loadHDF5chann:$(fimg)
    setChanResolution:1,$(vs[1]),$(vs[2]),$(vs[3])
    setChanAbsOffset:,1,$(phyOffset[1]),$(phyOffset[2]),$(phyOffset[3])
    loadHDF5seg:$(fsgm)
    setSegResolution:1,$(vs[1]),$(vs[2]),$(vs[3])
    setSegAbsOffset:1,$(phyOffset[1]),$(phyOffset[2]),$(phyOffset[3])
    mesh
    quit
    """
    # write the cmd file
    f = open(fcmd, "w")
    write(f, cmd)
    close(f)

    # run omnifycation
    run(`$(e.params[:ombin]) --headless --cmdfile=$(fcmd)`)
end
