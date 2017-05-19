using S3Dicts
using BigArrays

ba = BigArray( S3Dict("s3://neuroglancer/pinky40_v10/image/4_4_40/") )


#vol = ba[28161:28672, 25089:25600, 65:128]
#vol = ba[15873:16384, 31745:32256, 65:128]
#vol = ba[31053:32453, 39336:40336,   212:218]
#vol = ba[18193:19193, 37789:39789, 213:216]
vol = ba[14337:14337+2112-1, 7681:7681+2112-1, 1:136]

using HDF5
h5write("/usr/people/jingpeng/pinky/image.h5", "main", vol)

using Images
using FileIO

vol = reinterpret(N0f8, vol)
for z in 1:size(vol, 3)
    @show z
    img = vol[:,:,z]
    @show size(img)
    save(expanduser("~/pinky/image_$(z).png"), img )
end

