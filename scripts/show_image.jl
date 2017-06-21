using S3Dicts
using GSDicts
using BigArrays
using BigArrays.H5sBigArrays
using BigArrays.AlignedBigArrays
#ba = BigArray( S3Dict("s3://neuroglancer/pinky40_v10/image/4_4_40/") )
#ba = AlignedBigArray( "/mnt/data01/datasets/zebrafish/4_aligned/" )


#vol = ba[28161:28672, 25089:25600, 65:128]
#vol = ba[15873:16384, 31745:32256, 65:128]
#vol = ba[31053:32453, 39336:40336,   212:218]
#vol = ba[18193:19193, 37789:39789, 213:216]
#vol = ba[20481:20992, 28673:29184, 17793:17856]

#ba = BigArray( GSDict("gs://neuroglancer/pinky40_v11/qsemanticmap-5-x/128_128_40/") )
#vol = ba[321:321+1792-1, 129:129+1280-1, 1:1004]

#ba = BigArray( GSDict("gs://neuroglancer/pinky40_v11/image/16_16_40/") )
#vol = ba[2561:2561+1024-1, 1025+10240-1024:1025+10240-1, 1:1004]
#vol = ba[2561+14336-1024:2561+13824-1, 1025+10240-1024:1025+10240-1, 1:1004]

ba = BigArray( GSDict("gs://neuroglancer/zfish_v1/image/5_5_45/") )
vol = ba[51393:52416, 20929:21952, 17961:18088]

using HDF5
#h5write("/usr/people/jingpeng/pinky40/semanticmap_all.h5", "main", vol)
#vol = h5read("/usr/people/jingpeng/pinky40/image_chunk_2.h5", "main")

using Images
using FileIO

vol = reinterpret(N0f8, vol)
@sync begin
    for z in 1:size(vol, 3)
        @async begin 
            @show z 
            save(expanduser("~/Downloads/images/image_$(z).png"), vol[:,:,z])
        end 
    end
end

