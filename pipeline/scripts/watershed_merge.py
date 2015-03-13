import numpy
from global_vars import *
import h5py

#open channel data
znn_merged = h5py.File('../watershed/znn_merged.hdf5', "r" )
#Remove the first dimension which is 3, because of the affinity
desired_size = numpy.asarray(znn_merged['/main'].shape)[1:4]
print desired_size
znn_merged.close()

#Segmentation output file
merged_file = h5py.File('../omnify/watershed_merged.hdf5', "w" )

dendValues = numpy.fromfile('../watershed/data/input.dend_values', dtype='float32' )
dendValues_dset = merged_file.create_dataset('/dendValues', data=dendValues, dtype='float32')


dend = numpy.fromfile('../watershed/data/input.dend_pairs', dtype = 'uint32').reshape(-1,2).transpose()
dend_dset = merged_file.create_dataset('/dend', data=dend, dtype='uint32')

#Read the metadata to find out how many chunks we have
metadata = numpy.fromfile('../watershed/data/input.metadata', dtype='uint32')[2:5][::-1]
#read sizes to get individual chunks size
chunksizes = numpy.fromfile('../watershed/data/input.chunksizes', dtype='uint32').reshape(-1,3)
print chunksizes

main_dset = merged_file.create_dataset('/main', desired_size , dtype='uint32' )
chunk_number = 0
zabs = 0
for z_chunk in range(metadata[0]):
    yabs = 0
    for y_chunk in range(metadata[1]):
        xabs = 0
        for x_chunk in range(metadata[2]):

            chunk_size = chunksizes[chunk_number][::-1]

            print 'reading {0}/{1}/{2}/.seg'.format(z_chunk, y_chunk, x_chunk) , ' with size ', chunk_size

            main_chunk = numpy.fromfile('../watershed/data/input.chunks/{0}/{1}/{2}/.seg'.format(z_chunk, y_chunk, x_chunk), dtype='uint32').reshape(chunk_size)
            print main_chunk.shape , numpy.prod(chunk_size)
            main_dset[zabs:zabs+chunk_size[0], yabs:yabs+chunk_size[1], xabs:xabs+chunk_size[2]] = main_chunk
            

            #for next loop
            chunk_number += 1
            xabs += chunk_size[2] -1
        yabs += chunk_size[1] -1
    zabs += chunk_size[0] -1

merged_file.close()
print 'finished merging'