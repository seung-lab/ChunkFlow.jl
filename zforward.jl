export zforward

# here array could also be a hdf5/tif image file
typealias Tarrfile Any
#Union{AbstractString, Array}

function arr2path(tmp_dir, inps::Dict, key::AbstractString)
    # automatic input transformation
    if typeof( inps[key] ) <: Array
        farr = joinpath(tmp_dir, "$(key).h5")
        imsave(inps[key], farr)
        return farr
    elseif typeof( inps[key] ) <: AbstractString
        return inps[key]
    end
end

"""
create temporal dataset specification file
"""
function create_dataset_spec(tmp_dir::AbstractString, inps::Dict)
    fimg = arr2path(tmp_dir, inps, "img")
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
        fnames = $(tmp_dir)/out_sample1_output_0.tif
        pp_types = symetric_rescale
        is_auto_crop = yes
        fmasks =

        [sample1]
        input = 1
        rinput = 10
        """
    end

    # write the spec file
    f = open("$(tmp_dir)/dataset.spec", "w")
    write(f, dspec)
    close(f)
end

function create_config(prms, inps)
    tmp_dir = prms["tmp_dir"]

    # standard IO or not
    if prms["is_stdio"]
        stdio = "yes"
    else
        stdio = "no"
    end
    outsz = prms["outsz"]
    # configuration string
    conf="""
    [parameters]
    fnet_spec = $(prms["fnet_spec"])
    cost_fn = auto
    fdata_spec = $(tmp_dir)/dataset.spec
    num_threads = 0
    dtype = float32
    out_type = $(prms["out_type"])
    forward_range = 1
    is_bd_mirror = yes
    forward_net = $(prms["fnet"])
    is_stdio = $(stdio)
    forward_conv_mode = fft
    forward_outsz = $(outsz[1]),$(outsz[2]),$(outsz[3])
    output_prefix = $(tmp_dir)/out
    """
    # write the config file
    f = open("$(tmp_dir)/forward.cfg", "w")
    write(f, conf)
    close(f)
end

function zforward( prms::Dict{AbstractString, Any}, inps::Dict )
    tmp_dir = prms["tmp_dir"]
    # create dataset specification file
    create_dataset_spec( tmp_dir, inps )
    # create forward pass stage 1 configuration file
    create_config( prms, inps )
    # current path
    cp = pwd()
    # run recursive forward pass
    cd("$(prms["dir"])/python")
    run(`python forward.py -c $(tmp_dir)/forward.cfg -n $(prms["fnet"]) -r 1`)
    cd(cp)
    # move the output affinity to destination
    outfname = joinpath(tmp_dir, "out_sample1_output.h5")
    if contains(prms["out_type"], "aff")
        fout = joinpath(tmp_dir, "aff.h5")
        ret = Dict( "aff"=>fout )
    else
        fout = joinpath(tmp_dir, "bdr.h5")
        ret = Dict( "bdr"=>fout )
    end
    if outfname != prms["faff"]
        mv(outfname, fout, remove_destination=true)
    end
    return ret
end
