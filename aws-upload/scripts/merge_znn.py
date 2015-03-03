import os
import numpy
import re
import h5py

#We will iterate through all folders to check that the output is there
#We count how many chunks are there, and the size of the largest chunk
#We assume that all the chunks has similar size
#Based on this we will decide how many times we should divide the chunks

max_x, max_y, max_z = 0,0,0
max_chunk_size = numpy.array([0 , 0, 0])
for chunk_dir in os.listdir('../data/'):
  	
	#Get max chunk size in voxels
	try: 
		chunk_size = numpy.fromfile( '../data/{0}/output/stage21.0.size'.format(chunk_dir), dtype='uint32')[::-1]
		if numpy.any(max_chunk_size < chunk_size):
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

divs =  numpy.array([max_z+1, max_y+1 , max_x+1])
print max_chunk_size , divs
total_size = numpy.concatenate((numpy.array([3]) , max_chunk_size * divs))
chunk_size = numpy.concatenate((numpy.array([3]) , max_chunk_size ))


f = h5py.File('../watershed/znn_merged.hdf5', "w" )

print total_size, chunk_size 

dset = f.create_dataset('/main', tuple(total_size) , chunks=tuple(chunk_size) , compression="gzip")

zabs = 0 
for z_znn in range(max_z+1):
	yabs = 0
	for y_znn in range(max_y+1):
		xabs = 0
		for x_znn in range(max_x+1):

			chunk_dir = 'z{0}-y{1}-x{2}'.format(z_znn,y_znn,x_znn)
			#Load znn chunks and concatenate it in one affinity, we assume this can fit in memory
			#If it doesn't we should make znn chunks smaller
			znn_chunk_size = numpy.fromfile('../data/{0}/output/stage21.0.size'.format(chunk_dir), dtype='uint32')[::-1]
			znn_chunk_0 =  numpy.fromfile('../data/{0}/output/stage21.0'.format(chunk_dir), dtype='double').reshape(znn_chunk_size)
			znn_chunk_1 =  numpy.fromfile('../data/{0}/output/stage21.1'.format(chunk_dir), dtype='double').reshape(znn_chunk_size)
			znn_chunk_2 =  numpy.fromfile('../data/{0}/output/stage21.2'.format(chunk_dir), dtype='double').reshape(znn_chunk_size)
			znn_chunk_affinity = numpy.concatenate((znn_chunk_0[None,...],znn_chunk_1[None,...],znn_chunk_2[None,...]), axis=0)

			print chunk_dir, znn_chunk_size

			dset[:, zabs:zabs+znn_chunk_size[0], yabs:yabs+znn_chunk_size[1], xabs:xabs:znn_chunk_size[2]] = znn_chunk_affinity

			zabs = zabs+znn_chunk_size[0]
			yabs = yabs+znn_chunk_size[1]
			xabs = xabs+znn_chunk_size[2]

f.close()
