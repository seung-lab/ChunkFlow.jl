using BigArrays
using GSDicts
using S3Dicts

#ba = BigArray( GSDict("gs://neuroglancer/pinky40_v11/qaffinitymap-jnet-x/128_128_40/") )

#aff = ba[321:321+1792-1, 129:129+1280-1, 1:1004, 1]


#di = S3Dict("s3://neuroglancer/pinky40_v3/image/4_4_40/")
#bai = BigArray(di)
#img = bai[36353+2048:36864+2048+512+1024, 58369+2048:58880+2048+512+1024, 321-64:384]

#using HDF5
#h5write(expanduser("~/test.img.h5"), "main", img)
#quit()

#d = S3Dict("s3://neuroglancer/pinky40_v11/semanticmap-4/4_4_40/")
#d = S3Dict("s3://neuroglancer/pinky40_v11/affinitymap-jnet/4_4_40/")

ba = BigArray( S3Dict("s3://neuroglancer/zfish_v2/affinitymap/5_5_45/") )
aff = ba[44033:45055, 21505:22527, 17921:18047,1]
using BigArrays.H5sBigArrays
#ba = H5sBigArray("/usr/people/jingpeng/seungmount/research/Jingpeng/14_zfish/affinitymap/")
#aff = ba[51393-200:51393+833, 20929+50:20929+577, 17961+23:17961+88, 1]
# aff = ba[14337:14337+1024-1, 7681:7681+1024-1, 65:128, 1]
#aff = ba[19457:19457+1024-1, 19457:19457+1024-1, 16513:16513+128-1, 1:3]

using HDF5
#h5write("/usr/people/jingpeng/pinky40/affinitymap/aff_128_128_40.h5", "main", aff)
# using ImageView
# imshow(affx)

using Images
using FileIO

# transform int type in case the affinitymap was quantized
if eltype(aff) == UInt8
    aff = reinterpret(N0f8, aff)
end 

for c in 1:size(aff, 4)
    @sync begin
        for z in 1:size(aff, 3)
            @async begin 
                @show z
                img = aff[:,:,z,c]
                @show size(img)
                save(expanduser("~/Downloads/affinitymap/section_$(z)_$c.png"), img)
            end
        end
    end 
end
