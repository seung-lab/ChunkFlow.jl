using BigArrays

using BigArrays.AlignedBigArrays
ba = AlignedBigArray(expanduser("/mnt/data01/datasets/zebrafish/4_aligned/registry.txt"));
vol = ba[56321-16384*2:56321-16384*2+512-1,  33281-16384*2:33281-16384*2+512-1, 33921-16384*2-4:33921-16384*2+128-1]

#using GSDicts
#ba = BigArray( GSDict("gs://neuroglancer/zfish_v1/image/5_5_45/") )
#vol = ba[56321-16384:56321-16384+512-1,  33281-16384:33281-16384+512-1, 33921-16384-4:33921-16384+128-1]

#using S3Dicts
#ba = BigArray( S3Dict("s3://neuroglancer/zfish_v2/affinitymap/5_5_45/") )
#affx = ba[56321:56321+512-1, 33281:33281+512-1, 33921:33921+128-1, 1][:,:,:,1]

# using ImageView
# imshow(affx)

using Images
using FileIO


for z in 1:size(vol, 3)
    @show z
    save(expanduser("~/zfish/image_$(z).png"), vol[:,:,z])
end
