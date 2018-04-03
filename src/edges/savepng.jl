using S3Dicts
using BigArrays
using BigArrays.Chunks
using Images
using FileIO
"""
cutout the images across chunks and save as png file for fast checking of vertical line bug
"""

function nf_savepng(
            c       ::DictChannel,
            params  ::OrderedDict{Symbol, Any},
            inputs  ::OrderedDict{Symbol, Any},
            outputs ::OrderedDict{Symbol, Any})
    
    chk = fetch(c, inputs[:chunk])
    im = get_data(chk)
    @assert size(im, 3) == 1
    #@assert size(im, 4) == 1
    im = reshape(im, size(im)[1:2])

    start = get_origin(chk)
    stop  = start .+ [size(chk)...]
    fileName = "/tmp/cutout_$(start[1])-$(stop[1])_$(start[2])-$(stop[2])_$(start[3])-$(stop[3]).png"
    FileIO.save(fileName, im) 
    run(`aws s3 mv $fileName  $(params[:outputDir])`)
end

