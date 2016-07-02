export zforward

"""
get image file name from an array or a filename
"""
function arr2path(tmpdir, inps::Dict, key::Symbol)
    # automatic input transformation
    if typeof( inps[key] ) <: Array
        farr = joinpath(tmpdir, "$(key).h5")
        imsave(inps[key], farr)
        return farr
    elseif typeof( inps[key] ) <: AbstractString
        return inps[key]
    end
end

"""
create temporal dataset specification file
"""
function create_dataset_spec(tmpdir::AbstractString, inps::Dict)
    fimg = arr2path(tmpdir, inps, "img")
    dspec = """
    [image1]
    fnames = $(fimg)
    pp_types = standard2D
    is_auto_crop = yes

    [sample1]
    input = 1
    """
    # if has boundary map, it is the second stage
    if haskey(inps, "bdr")
        dspec = """
        [image1]
        fnames = $(fimg)
        pp_types = standard2D
        is_auto_crop = yes

        [image10]
        fnames = $(tmpdir)/out_sample1_output_0.tif
        pp_types = symetric_rescale
        is_auto_crop = yes
        fmasks =

        [sample1]
        input = 1
        rinput = 10
        """
    end

    # write the spec file
    f = open("$(tmpdir)/dataset.spec", "w")
    write(f, dspec)
    close(f)
end

function create_config(d)
    tmpdir = d[:tmpdir]

    # standard IO or not
    is_stdio = d[:is_stdio] ? "yes" : "no"
    is_bd_mirror = d[:is_bd_mirror] ? "yes" : "no"

    outsz = d[:outsz]
    # configuration string
    conf="""
    [parameters]
    fnet_spec = $(d[:fnet_spec])
    cost_fn = auto
    fdata_spec = $(tmpdir)/dataset.spec
    num_threads = 0
    dtype = float32
    out_type = $(d[:out_type])
    forward_range = 1
    is_bd_mirror = $(is_bd_mirror)
    forward_net = $(d[:fnet])
    is_stdio = $(is_stdio)
    forward_conv_mode = $(d[:conv_mode])
    forward_outsz = $(outsz[1]),$(outsz[2]),$(outsz[3])
    output_prefix = $(tmpdir)/out
    """
    # write the config file
    f = open("$(tmpdir)/forward.cfg", "w")
    write(f, conf)
    close(f)
end

function zforward( d::Dict{Symbol, Any} )
    if contains(d[:node_switch], "off")
        return
    end
    println("znn forward pass...")
    if isfile(d[:faff])
        println("remove existing affinity file...")
        rm(d[:faff])
    end

    inps = Dict( :img=> d[:fimg] )

    tmpdir = d[:tmpdir]
    # create dataset specification file
    create_dataset_spec( tmpdir, inps )
    # create forward pass stage 1 configuration file
    create_config( d )
    # current path
    cp = pwd()
    # run recursive forward pass
    cd("$(d[:dir])/python")
    run(`python forward.py -c $(tmpdir)/forward.cfg -n $(d[:fnet]) -r 1`)
    cd(cp)
    # move the output affinity to destination
    outfname = joinpath(tmpdir, "out_sample1_output.h5")
    fout = joinpath(tmpdir, "aff.h5")
    ret = Dict( :aff=>fout )

    # crop both image and affinity
    if !is_bd_mirror
        cropsize = (d[:fov]-1) / 2
        img = readimg(d[:fimg])
        img = crop_border(img, cropsize)
        rm(d[:fimg])
        saveimg()

    if outfname != d[:faff]
        mv(outfname, fout, remove_destination=true)
    end

    return ret
end
