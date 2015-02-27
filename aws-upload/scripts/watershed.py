memory =  10 * 10**9#gb
threads = 8


import os
import numpy
import re
from subprocess import call


#We will iterate through all folders to check that the output is there
#We count how many chunks are there, and the size of the largest chunk
#We assume that all the chunks has similar size
#Based on this we will decide how many times we should divide the chunks

max_x, max_y, max_z = 0,0,0
max_chunk_size = 0
for chunk_dir in os.listdir('../data/'):
  	
	#Get max chunk size in voxels
	try: 
		chunk_size = numpy.prod(numpy.fromfile( '../data/{0}/output/stage21.0.size'.format(chunk_dir), dtype='uint32'))
		if max_chunk_size < chunk_size:
			max_chunk_size =  chunk_size
	except:
		#raise in production
		print Exception("There is no stage 2 output in chunk {0}".format(chunk_dir))

  	m = re.match(r'z(\d+)-y(\d+)-x(\d+)',chunk_dir)
	z = int(m.group(1)) ; y = int(m.group(2)); x = int(m.group(3))
	
	if z > max_z:
		max_z = z

	if y > max_y:
		max_y = y
	
	if x > max_x:
		max_x = x


znn_chunks = (max_x+1) * (max_y+1) * (max_z+1)
#The larger the chuncks watershed process in parallel the better
#Divide the avaiable memory by the number of threads, that should be the size of a chunk.
#Watershed requires about 20 bytes per voxel.

chunk_max_memory = memory / threads / 20 

#Compute this based on chunkMaxSize and  chunk_max_memory
chunk_divs = numpy.ceil(max_chunk_size/chunk_max_memory).astype(int)
print 'We will divide each znn chunk in {0} parts, because we have {1} znn chunks, we will have {2} watershed chunks in total'.format(chunk_divs,znn_chunks,chunk_divs * znn_chunks)

if not os.path.exists('../watershed/data'):
	os.makedirs('../watershed/data')
else:
    #For production
    raise Exception('folder already exists')

affin = numpy.zeros(shape=(10,10,10))

sizes = open('../watershed/data/input.chunksizes','w')
affinities = open('../watershed/data/input.affinity.data','w')
os.makedirs('../watershed/data/input.chunks')

#Iterate trough znn chunks
zabs = 0
for z_znn in range(max_z+1):
	yabs = 0
	for y_znn in range(max_y+1):
		xabs = 0
		for x_znn in range(max_x+1):

			os.makedirs('../watershed/data/input.chunks/{0}/{1}/{2}'.format(x_znn,y_znn,z_znn))

			#Load znn chunks and concatenate it in one affinity, we assume this can fit in memory
			#If it doesn't we should make znn chunks smaller
			znn_chunk_size = numpy.fromfile('../data/{0}/output/stage21.0.size'.format(chunk_dir), dtype='uint32')
			znn_chunk_0 =  numpy.fromfile('../data/{0}/output/stage21.0'.format(chunk_dir), dtype='double').reshape(znn_chunk_size)
			znn_chunk_1 =  numpy.fromfile('../data/{0}/output/stage21.1'.format(chunk_dir), dtype='double').reshape(znn_chunk_size)
			znn_chunk_2 =  numpy.fromfile('../data/{0}/output/stage21.2'.format(chunk_dir), dtype='double').reshape(znn_chunk_size)
			znn_chunk_affinity = numpy.concatenate((znn_chunk_0[None,...],znn_chunk_1[None,...],znn_chunk_2[None,...]), axis=0)

			z_max = znn_chunk_size[0]
		
			for z_chunk_max in numpy.linspace(0, z_max , chunk_divs +1):

				z_chunk_max = z_chunk_max.astype(int)

				if z_chunk_max == 0:
					z_chunk_min = 0
					continue
				
				print 'prepared chunk {0}:{1}:{2} size: [ {3} {4} {5} ]'.format(xabs, yabs, zabs, znn_chunk_size[2], znn_chunk_size[1], znn_chunk_size[0])
				
				affin = znn_chunk_affinity[:,z_chunk_min:z_chunk_max,:,:]
				print affin.shape
				affinities.write(affin.tostring())
				sz = numpy.asarray(affin.shape).astype('int32')
				sizes.write(sz.tostring())

				#For next loop
				zabs += 1;
				z_chunk_min = z_chunk_max

		xabs+=1
	yabs+=1

sizes.close()
affinities.close()

#Write metedata to file
numpy.array([32, 32, xabs, yabs, zabs]).astype('int32').tofile('../watershed/data/input.metadata')

#Run watershed
call(["../watershed/src/zi/watershed/main/bin/xxlws", "--filename=../watershed/data/input", "--high=0.99", "--low=0.1", "--dust=25", "--dust_low=0.1"])
