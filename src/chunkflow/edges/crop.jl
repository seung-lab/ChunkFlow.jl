using EMIRT
using DataStructures

function ef_crop!( c::DictChannel, e::Edge)
    println("-------start crop--------------")
    for (k,v) in e.inputs
        @assert haskey(e.outputs, k)
        chk = fetch(c, v)
        chk = crop_border!(chk, e.params[:cropsize])
        put!(c, e.outputs[k], chk)
    end
    println("-------crop end----------------")
end
