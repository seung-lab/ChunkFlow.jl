using BigArrays

using S3Dicts

di = S3Dict("s3://neuroglancer/pinky40_v3/image/4_4_40/")
bai = BigArray(di)
img = bai[36353+2048:36864+2048+512+1024, 58369+2048:58880+2048+512+1024, 321-64:384]

using HDF5
h5write(expanduser("~/test.img.h5"), "main", img)
#quit()

d = S3Dict("s3://neuroglancer/pinky40_v3/affinitymap-jnet/4_4_40/")

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
# aff = ba[75265:75776,19969:20480,65:128, 1:3]
# aff = ba[79361:79872, 20993:21504, 1:128, 1:3]
# aff = ba[72704:73216,20480:20992, 128:192]
# aff = ba[26625:26625+512, 26625:26625+512, 1:64, 1:3]
# aff = ba[79872+1:79872+1024,20993:20992+1024,65:128+64, 1:3]
#aff = ba[83457:83968, 33281:33792, 129:256, 1:3]
#aff = ba[9727-4096:10240-4096, 31233+4096:31744+4096, 65:192, 1:3]
#aff = ba[10241:10752, 26113:26624, 129:256, 1:3]
aff = ba[36353+2048:36864+2048+512+1024, 58369+2048:58880+2048+512+1024, 321-64:384, 1:3]

using HDF5
h5write("/usr/people/jingpeng/test.aff.h5", "main", aff)


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
