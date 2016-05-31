import Images
#using HDF5
#using Watershed
#import Escher:  @api, render
include("../core/aff2segm.jl")

"""
the tile containing input form of all parameters
"""
function tile_form_seg(ses::Sampler)
    return vbox(
                h2("Choose the affinity file"),
                watch!(ses, :input1, textinput("/tmp/aff.h5", label="affinity file")),
                vskip(1em),
                h2("The output segmentation file name"),
                watch!(ses, :input2, textinput("/tmp/seg.h5", label="output segmentation ")),
                trigger!(ses, :submit, button("Segment"))
                ) |> maxwidth(400px)
end


function tile_result_seg(faff, fseg)
    if !isfile( faff )
        return "I have not found the affinity file!"
    else
        # read affinity and segment
        aff = readaff(faff)
        sgm = aff2segm(aff, 0.1, 0.8)
        savesgm(fseg, sgm)

        # show affinity and segmentation
        #iaff = Images.Image(aff, colordim=4, spatialorder=["x","y","z"], pixelspacing=[1,1,5])
        iaff = Images.Image(aff[:,:,1,1], spatialorder=["x","y"])
        iseg = Images.Image(sgm.seg, spatialorder=["x","y","z"], pixelspacing=[1,1,5])
        exp = Images.load("/usr/people/jingpeng/Pictures/libraries.png")
        return exp  #hbox([iaff[:,:,1,1], iseg[:,:,1]])
    end
end

function segmentation()
    seinp = Signal(Dict())
    ses = Escher.sampler()

    seform = tile_form_seg(ses)
    return map(seinp) do sed
        vbox(
             intent(ses, seform) >>> seinp,
             vskip(2em),
             tile_result_seg( get(sed,:input1, ""), get(sed, :input2,"") ),
             string(sed)
             ) |> Escher.pad(2em)
    end
end
