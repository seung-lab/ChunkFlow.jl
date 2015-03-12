import os
import numpy
import re
from subprocess import call
import h5py

from global_vars import *

#Read the merged znn output
f = h5py.File('../watershed/znn_merged.hdf5', 'r')
znn = f['/main']

#The larger the chuncks watershed process in parallel the better
#Divide the avaiable memory by the number of threads, that should be the size of a chunk.
#Watershed requires about 20 bytes per voxel.
chunk_max_memory = memory / threads / 20 

#Check how many divs we need, divide each axis the same ammount of times
required_divs = numpy.prod(znn.shape) /chunk_max_memory + 1.0
required_divs = int(required_divs) 

best_score = numpy.float('inf')
best_divs = None
#Minimize overlapping
for z in range(1,required_divs+1):
	for y in range(1,required_divs+1):
		for x in range(1,required_divs+1):
			
			if x*y*z > required_divs:
				continue

			test_divs = numpy.array([z,y,x])
			score = numpy.std(numpy.asarray(znn.shape)[1:4] / test_divs)
			if score < best_score:
				best_score = score
				best_divs = test_divs

width = numpy.ceil( znn.shape[1:4] / best_divs -1 ).astype(int)

if not os.path.exists('../watershed/data'):
	os.makedirs('../watershed/data')
else:
	#For test
	import shutil
	shutil.rmtree('../watershed/data')
	os.makedirs('../watershed/data')

    #For production
    #raise Exception('folder already exists')


chunksizes = open('../watershed/data/input.chunksizes','w+')
affinities = open('../watershed/data/input.affinity.data','w+')
os.makedirs('../watershed/data/input.chunks')



for z_chunk in range(0, best_divs[0]):
	if z_chunk == 0:
		z_chunk_min = 0
		

	z_chunk_max = z_chunk_min + width[0]

	for y_chunk in range(0 , best_divs[1]):
		if y_chunk == 0:
			y_chunk_min = 0
			
		y_chunk_max = y_chunk_min + width[1]


		for x_chunk in range(0, best_divs[2]):
			if x_chunk == 0:
				x_chunk_min = 0
				
			x_chunk_max = x_chunk_min + width[2]
	

			os.makedirs('../watershed/data/input.chunks/{0}/{1}/{2}'.format(x_chunk, y_chunk, z_chunk))
			cfrom = numpy.array([z_chunk_min, y_chunk_min, x_chunk_min]) - 1
			cfrom[cfrom < 0] = 0
			cto = numpy.array([z_chunk_max, y_chunk_max, x_chunk_max]) + 1
			cto = numpy.minimum(cto, znn.shape[1:4])
			size = cto - cfrom

			print 'prepared chunk {0}:{1}:{2} , position [{3}-{4} , {5}-{6}, {7}-{8}] size: [ {9} {10} {11} ]'.format(z_chunk, y_chunk, x_chunk,cfrom[0],cto[0],cfrom[1], cto[1],cfrom[2], cto[2] , size[0], size[1], size[2])
			
			affin = znn[:,cfrom[0]:cto[0], cfrom[1]:cto[1], cfrom[2]:cto[2]].astype('float32')
			affin.tofile(affinities)

			sz = numpy.asarray(affin.shape[1:4])[::-1].astype('uint32')
			sz.tofile(chunksizes)

			x_chunk_min = x_chunk_max
		y_chunk_min = y_chunk_max
	z_chunk_min = z_chunk_max

chunksizes.close()
affinities.close()

#Write metedata to file
#however the max ID is limited to 31 bits ~ 2 billion]  if using uint32s then the volumes should be <= 2G voxels just in case
#i guess i wouldnt make cubes bigger than 1k x 1k x 2k
# unless we want to use uint64s for IDs
metadata = numpy.concatenate(( numpy.array([64, 64]), best_divs[::-1] )).astype('int32')
print metadata
metadata.tofile('../watershed/data/input.metadata')

#Run watershed
print 'running watershed ...'
#there should be no spaces in the arguments, otherwise it doesn't work
call(["../watershed/src/zi/watershed/main/bin/xxlws", "--filename=../watershed/data/input", "--high=0.99", "--low=0.25", "--dust=400", "--dust_low=0.3"])

