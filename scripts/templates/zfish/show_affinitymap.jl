using BigArrays

using BigArrays.H5sBigArrays
ba = H5sBigArray(expanduser("~/seungmount/research/Jingpeng/14_zfish/affinitymap/"));
affx = ba[56321-16384:56321-16384+512-1,  33281-16384:33281-16384+512-1, 33921-16384:33921-16384+128-1,3:3][:,:,:,1]

#using S3Dicts
#ba = BigArray( S3Dict("s3://neuroglancer/zfish_v2/affinitymap/5_5_45/") )
#affx = ba[56321:56321+512-1, 33281:33281+512-1, 33921:33921+128-1, 1][:,:,:,1]

# using ImageView
# imshow(affx)

using Images
using FileIO


for z in 1:size(affx, 3)
    @show z
    img = affx[:,:,z]
    save(expanduser("~/zfish/affx_$(z).png"), img)
end
