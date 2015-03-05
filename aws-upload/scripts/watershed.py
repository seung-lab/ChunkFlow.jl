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
required_divs = numpy.prod(znn.shape) /chunk_max_memory

chunk_divs = numpy.array([1 , 1 , 1]) * required_divs**.333 
chunk_divs = numpy.ceil(chunk_divs).astype(int)


if not os.path.exists('../watershed/data'):
	os.makedirs('../watershed/data')
else:
	#For test
	import shutil
	shutil.rmtree('../watershed/data')
	os.makedirs('../watershed/data')

    #For production
    #raise Exception('folder already exists')


sizes = open('../watershed/data/input.chunksizes','w')
affinities = open('../watershed/data/input.affinity.data','w')
os.makedirs('../watershed/data/input.chunks')


#Iterate trough watershed chunks
#remember the first dimension of znn is 3, because in an affinity
zabs = 0
for z_chunk_max in numpy.linspace(0, znn.shape[1] , chunk_divs[0]+1):
	z_chunk_max = z_chunk_max.astype(int)
	if z_chunk_max == 0:
		z_chunk_min = 0
		continue

	yabs = 0
	for y_chunk_max in numpy.linspace(0, znn.shape[2] , chunk_divs[1] +1):
		y_chunk_max = y_chunk_max.astype(int)
		if y_chunk_max == 0:
			y_chunk_min = 0
			continue


		xabs = 0
		for x_chunk_max in numpy.linspace(0, znn.shape[3], chunk_divs[2]+1):
			x_chunk_max = x_chunk_max.astype(int)
			if x_chunk_max == 0:
				x_chunk_min = 0
				continue


			os.makedirs('../watershed/data/input.chunks/{0}/{1}/{2}'.format(xabs,yabs,zabs))
			cfrom = numpy.array([z_chunk_min, y_chunk_min, x_chunk_min]) - 1
			cfrom[cfrom < 0] = 0
			cto = numpy.array([z_chunk_max, y_chunk_max, x_chunk_max]) + 1
			cto = numpy.minimum(cto, znn.shape[1:4])

			size = cto - cfrom

			print 'prepared chunk {0}:{1}:{2} , position [{3}-{4} , {5}-{6}, {7}-{8}] size: [ {9} {10} {11} ]'.format(xabs, yabs, zabs,cfrom[0],cto[0],cfrom[1], cto[1],cfrom[2], cto[2] , size[0], size[1], size[2])
				
			affin = znn[:,cfrom[0]:cto[0], cfrom[1]:cto[1], cfrom[2]:cto[2]]
			affinities.write(affin.tostring())
			sz = numpy.asarray(affin.shape[1:4]).astype('int32')
			sizes.write(sz.tostring())

			xabs+=1
			x_chunk_min = x_chunk_max
		yabs+=1
		y_chunk_min = y_chunk_max
	zabs+=1
	z_chunk_min = z_chunk_max

sizes.close()
affinities.close()

#Write metedata to file
numpy.array([32, 32, xabs, yabs, zabs]).astype('int32').tofile('../watershed/data/input.metadata')

#Run watershed
call(["../watershed/src/zi/watershed/main/bin/xxlws", "--filename=../watershed/data/input", "--high=0.99", "--low=0.1", "--dust=25", "--dust_low=0.1"])
