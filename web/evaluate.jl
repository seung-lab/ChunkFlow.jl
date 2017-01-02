using Gadfly
using HDF5
using EMIRT
#using Escher

ecs = ScoreCurves()

"""
the form tile to provide learning curve plotting tile
"""
function tile_form_evaluate(evs::Sampler)
    vbox(
         h2("Choose the segmentation file"),
         watch!(evs, :input1, textinput("/tmp/sgm.h5", label="segmentation file with segmentPairsrogram")),
         vskip(1em),
         h2("Choose the label file"),
         watch!(evs, :input2, textinput("/tmp/lbl.h5", label="label file")),
         trigger!(evs, :submit, button("Evaluate Segmenation"))
         ) |> maxwidth(400px)
end

"""
the tile of evaluate result
"""
function evaluate_result(fsgm::AbstractString, flbl::AbstractString)
    if !isfile(fsgm)
        return "segmentation file not found!"
    elseif !issgmfile(fsgm)
        return "this file do not have strandard segmentation with segmentPairsrogram format."
    elseif !isfile(flbl)
        return "ground truth label not found!"
    else
        # read files
        sgm = readsgm(fsgm)
        lbl = readseg(flbl)
        ec = sgm2ec(sgm,lbl)
        push!(ecs, ec)
        return plot(ecs)
    end
end

"""
the page of evaluate
"""
function evaluate()
    evinp = Signal(Dict())
    evs = Escher.sampler()

    evform = tile_form_evaluate(evs)
    ret = map(evinp) do evdict
        vbox(
             intent(evs, evform) >>> evinp,
             vskip(2em),
             evaluate_result(get(evdict, :input1, ""), get(evdict,:input2, "")),
             string(evdict)
             ) |> Escher.pad(2em)
    end
    return ret
end
