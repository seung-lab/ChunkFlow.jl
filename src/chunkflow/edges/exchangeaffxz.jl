using EMIRT
using DataStructures

export ef_exchangeaffxz!

"""
edge function of exchangeaffxz
exchange the X and Z axis of affinity map.
The old version of znn output affinity channels as z,y,x,
while the inference needs x,y,z in watershed and agglomeration.
ZNN output x,y,z affinity map when setting up the "is_stdio = yes"
"""
function ef_exchangeaffxz!( c::DictChannel, e::Edge)
    println("------------start exchange xz of affinity map ------------")
    chk = fetch(c, e.inputs[:aff])
    @assert isaff(chk.data)
    chk.data = exchangeaffxz!(chk.data)
    put!(c, e.outputs[:aff], chk)
    println("-----------exchange aff xz end---------------------")
end
