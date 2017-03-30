using BigArrays

using BigArrays.H5sBigArrays

ba = H5sBigArray("~/seungmount/research/Jingpeng/14_zfish/affinitymap/");
# bb = boundingbox(ba)
# @show bb.start
# @show bb

# black region 1
# affx = ba [63249:63488,  26625:32768, 16897:17152, 1][:,:,:,1]
# affx = ba[63248:63489,  26624:32769, 16896:17151, 1][:,:,:,1]

# black region 2
# affx = ba[63249:63488,  27649:30720, 16641:16768,1][:,:,:,1]
affx = ba[63248:63489,  27648:30721, 16640:16769,1][:,:,:,1]

# using ImageView
# imshow(affx)

using Images
using FileIO


for z in 1:size(affx, 3)
    @show z
    img = affx[:,:,z]
    for i in eachindex(img)
        if img[i]>Float32(1)
            img[i] = Float32(1)
        elseif img[i] <Float32(0)
            img[i] = Float32(0)
        end
    end
    save(expanduser("~/zfish/affx_$(z).png"), img)
end
