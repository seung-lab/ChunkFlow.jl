function segm2omprj(ombin, fimg, fsegm, vs=[4,4,40], fomprj="/tmp/tmp.omni")
    # prepare the cmd file for omnification
    # make omnify command file
    cmd = """create:$(fomprj)
    loadHDF5chann:$(fimg)
    setChanResolution:1,$(vs[1]),$(vs[2]),$(vs[3])
    setChanAbsOffset:,1,0,0,0
    loadHDF5seg:$(fsegm)
    setSegResolution:1,$(vs[1]),$(vs[2]),$(vs[3])
    setSegAbsOffset:1,0,0,0
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
