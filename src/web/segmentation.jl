#using HDF5
#using Watershed
#import Escher:  @api, render
#include("../core/aff2segm.jl")

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
        # read affinity
        #aff = readaff(faff)
        #seg, dend, dendValues = aff2segm(aff, 0.1, 0.8)
        #save_segm(fseg, seg, dend, dendValues)
        return "done!"
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
             tile_result_seg( get(sed,:faff, ""), get(sed, :fseg,"/tmp/seg.h5") ),
             string(sed)
             ) #|> Escher.pad(2em)
    end
end
