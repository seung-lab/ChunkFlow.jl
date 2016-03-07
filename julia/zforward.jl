export zforward()

"""
create temporal dataset specification file
"""
function create_dataset_spec(tmp_dir, fimg)
    dspec = """
    [image1]
    fnames = $(fimg)
    pp_types = standard2D
    is_auto_crop = yes

    [image10]
    fnames = $(tmp_dir)/out_sample1_output_0.tif
    pp_types = symetric_rescale
    is_auto_crop = yes
    fmasks =

    [sample1]
    input = 1

    [sample10]
    input = 1
    rinput = 10
    """
    # write the spec file
    f = open("$(tmp_dir)/dataset.spec", 'w')
    write(f, dspec)
    close(f)
end

function create_config(stgid, tmp_dir, fnet_spec, fnet, outsz)
    # stage specific configuration
    if stgid == 1
        out_type = "boundary"
        sampleid = 1
    elseif stgid == 2
        out_type = "affinity"
        sampleid = 10
    else
        error("only support 1-2 stage configuration!")
    end

    # configuration string
    conf="""
    [parameters]
    fnet_spec = $(fnet_spec)
    fdata_spec = $(tmp_dir)/dataset.spec
    num_threads = 0
    dtype = float32
    out_type = $(out_type)
    forward_range = $(sampleid)
    forward_net = $(fnet)
    forward_conv_mode = fft
    forward_outsz = $(outsz[1]),$(outsz[2]),$(outsz[3])
    output_prefix = $(tmp_dir)/out
    """
    # write the config file
    f = open("$(tmp_dir)/forward.stg$(stgid).cfg", 'w')
    write(f, conf)
    close(f)
end

function zforward(tmp_dir, fimg)
    # create dataset specification file
    create_dataset_spec(tmp_dir, fimg)
    # create forward pass stage 1 configuration file
    create_config(1, tmp_dir, fnet_spec, fnet, outszs[1:3])
    # create forward pass stage 2 configuration file
    create_config(2, tmp_dir, fnet_spec, fnet, outszs[4:6])
    # run forward pass
    run(`cd ../python; python forward.py -c $(tmp_dir)/forward.stg1.cfg -n $(fnet) -r 1; cd ../julia`)
    run(`cd ../python; python forward.py -c $(tmp_dir)/forward.stg2.cfg -n $(fnet) -r 10; cd ../julia`)
end
