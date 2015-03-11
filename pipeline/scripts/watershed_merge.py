import numpy
from global_vars import *
import h5py

#open channel data
channel_dset = h5py.File('../watershed/znn_merged.hdf5', "r" )
#Remove the first dimension which is 3, because of the affinity
desired_size = numpy.asarray(channel_dset['/main'].shape)[1:4]
print desired_size
channel_dset.close()

#Segmentation output file
merged_file = h5py.File('../watershed/data/watershed_merged.hdf5', "w" )

dendValues = numpy.fromfile('../watershed/data/input.dend_values', dtype='float32' )
dendValues_dset = merged_file.create_dataset('/dendValues', data=dendValues, dtype='float32')


dend = numpy.fromfile('../watershed/data/input.dend_pairs', dtype = 'uint32').reshape(-1,2).transpose()
dend_dset = merged_file.create_dataset('/dend', data=dend, dtype='uint32')

#Read the metadata to find out how many chunks we have
metadata = numpy.fromfile('../watershed/data/input.metadata', dtype='uint32')[2:5]

#read sizes to get individual chunks size
chunksizes = numpy.fromfile('../watershed/data/input.chunksizes', dtype='uint32').reshape(-1,3)

main_dset = merged_file.create_dataset('/main', desired_size , dtype='uint32' )
chunk_number = 0
zabs = 0
for z_chunk in range(metadata[0]):
    yabs = 0
    for y_chunk in range(metadata[1]):
        xabs = 0
        for x_chunk in range(metadata[2]):

            print 'merging chunk ', z_chunk , y_chunk, x_chunk
            chunk_size = chunksizes[chunk_number][::-1]

            print chunk_size

            main_chunk = numpy.fromfile('../watershed/data/input.chunks/{0}/{1}/{2}/.seg'.format(x_chunk, y_chunk, z_chunk), dtype='uint32').reshape(chunk_size)
            main_dset[zabs:zabs+chunk_size[0], yabs:yabs+chunk_size[1], xabs:xabs+chunk_size[2]] = main_chunk
            

            #for next loop
            chunk_number += 1
            xabs += chunk_size[2]
        yabs += chunk_size[1]
    zabs += chunk_size[0]

merged_file.close()
print 'finished merging'