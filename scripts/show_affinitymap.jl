using BigArrays

using S3Dicts

#di = S3Dict("s3://neuroglancer/pinky40_v3/image/4_4_40/")
#bai = BigArray(di)
#img = bai[36353+2048:36864+2048+512+1024, 58369+2048:58880+2048+512+1024, 321-64:384]

#using HDF5
#h5write(expanduser("~/test.img.h5"), "main", img)
#quit()

d = S3Dict("s3://neuroglancer/pinky40_v11/semanticmap-4/4_4_40/")
#d = S3Dict("s3://neuroglancer/pinky40_v11/affinitymap-jnet/4_4_40/")

ba = BigArray(d)
# bb = boundingbox(ba)
# @show bb.start
# @show bb

# aff = ba[14337:14337+1024-1, 7681:7681+1024-1, 65:128, 1]
aff = ba[22817:22817+1024-1, 22960:22960+1024-1, 513:513+63, 1]

#using HDF5
#h5write("/usr/people/jingpeng/pinky/test.aff.h5", "main", aff)


# using ImageView
# imshow(affx)

using Images
using FileIO


for c in 1:size(aff, 4)
    for z in 1:size(aff, 3)
        @show z
        img = aff[:,:,z,c]
        @show size(img)
        save(expanduser("~/pinky/section_$(z)_$c.png"), img)
    end
end
