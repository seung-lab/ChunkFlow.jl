using BigArrays

using S3Dicts
d = S3Dict("s3://seunglab/pinky40_2/affinitymap/4_4_40/")

ba = BigArray(d)
# bb = boundingbox(ba)
# @show bb.start
# @show bb

# black region 1
# affx = ba [63249:63488,  26625:32768, 16897:17152, 1][:,:,:,1]
# affx = ba[63248:63489,  26624:32769, 16896:17151, 1][:,:,:,1]

# black region 2
# affx = ba[63249:63488,  27649:30720, 16641:16768,1][:,:,:,1]
# affx = ba[32769:33380,32769:33380,1:100,1][:,:,:,1]
# affx = ba[28161:28672,28161:28672,65:128, 1][:,:,:,1]
aff = ba[75265:75776,19969:20480,65:128, 1:3]
# using ImageView
# imshow(affx)

using Images
using FileIO


for c in 1:3
    for z in 1:size(aff, 3)
        @show z
        img = aff[:,:,z,c]
        # for i in eachindex(img)
        #     if img[i]>Float32(1)
        #         img[i] = Float32(1)
        #     elseif img[i] <Float32(0)
        #         img[i] = Float32(0)
        #     end
        # end
        save(expanduser("~/pinky/aff_$(z)_$c.png"), img)
    end
end
