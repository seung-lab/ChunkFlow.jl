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
function ef_exchangeaffxz!( c::DictChannel,
                    params::OrderedDict{Symbol, Any},
                    inputs::OrderedDict{Symbol, Any},
                    outputs::OrderedDict{Symbol, Any})
    chk = fetch(c, inputs[:aff])
    @assert isaff(chk.data)
    chk.data = exchangeaffxz!(chk.data)
    put!(c, outputs[:aff], chk)
end
