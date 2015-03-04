import numpy

from node_specification import *

dendValues = numpy.fromfile('../watershed/data/input.dend_values', dtype='single' )
dend = numpy.fromfile('../watershed/data/input.dend_pairs', dtype = 'uint32')
dend = dend.reshape((2, len(dendValues)))

#Read the metadata to find out how many chunks we have
metadata = numpy.fromfile('../watershed/data/input.metadata', dtype='uint32')[2:5]

#read sizes to get individual chunks size
sizes = numpy.fromfile('../watershed/data/input.chunksizes', dtype='uint32')
print sizes


chunksizes = numpy.fromfile('../watershed/data/input.chunksizes', dtype='uint32').reshape(-1,3)
print chunksizes


for z_chunk in range(metadata[0]):
    for y_chunk in range(metadata[1]):
        for x_chunk in range(metadata[2]):

            print x_chunk