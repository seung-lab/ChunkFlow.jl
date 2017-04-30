using S3Dicts
using BigArrays

ba = BigArray( S3Dict("s3://neuroglancer/pinky40_v8/image/4_4_40/") )


#vol = ba[28161:28672, 25089:25600, 65:128]
#vol = ba[15873:16384, 31745:32256, 65:128]
#vol = ba[31053:32453, 39336:40336,   212:218]
vol = ba[18193:19193, 37789:39789, 213:216]

using Images
using FileIO

vol = reinterpret(N0f8, vol)
for z in 1:size(vol, 3)
    @show z
    img = vol[:,:,z]
    @show size(img)
    save(expanduser("~/pinky/cutout_$(z).png"), img )
end

