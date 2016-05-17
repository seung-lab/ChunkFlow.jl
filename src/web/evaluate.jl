using Gadfly
using HDF5
import Escher: Sampler

"""
the form tile to provide learning curve plotting tile
"""
function tile_form_evaluate(evs::Sampler)
    return vbox(
                h2("Choose the segmentation file"),
                watch!(evs, :fseg, textinput("/tmp/seg.h5", label="segmentation file")),
                vskip(1em),
                h2("Choose the label file"),
                watch!(evs, :flbl, textinput("/tmp/lbl.h5", label="label file")),
                trigger!(evs, :submit, button("Evaluate Segmenation"))
                ) |> maxwidth(400px)
end



"""
the tile of evaluate result
"""
function evaluate_result(fseg::AbstractString, flbl::AbstractString)
    if isfile(fseg) && isfile(flbl)
        return "something"
    else
        return "nothing"
    end
end

"""
the page of evaluate
"""
function evaluate()
    evinp = Signal(Dict())
    evs = Escher.sampler()

    evform = tile_form_evaluate(evs)
    return map(evinp) do evdict
        vbox(
             intent(evs, evform) >>> evinp,
             vskip(2em),
             evaluate_result(get(evdict, :fseg, ""), get(evdict,:flbl, "")),
             string(evdict)
             ) |> Escher.pad(2em)
    end
end
