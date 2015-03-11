import os
import numpy
import re
import h5py
import znn

#We will iterate through all folders to check that the output is there
#We count how many chunks are there, and the size of the largest chunk
#We assume that all the chunks has similar size

max_x, max_y, max_z = 0,0,0
output_size = None
for chunk_dir in os.listdir('../znn/data/'):
  	
	#Get max chunk size in voxels
	try: 
		chunk_size = numpy.fromfile( '../znn/data/{0}/output/stage21.size'.format(chunk_dir), dtype='uint32')[::-1]

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

	if z == max_z and y == max_y and x == max_x:
		output_size = znn.load_output_size(chunk_dir)

divs =  numpy.array([max_z+1, max_y+1 , max_x+1])
output_size = numpy.array([3 , output_size['z_max'] , output_size['y_max'], output_size['x_max']])
chunk_size =  output_size.copy()
chunk_size[1] = 1

#We create and hdf5 with a chunk layout, we will load one znn chunk in memory at the time, and flush it to disk
f = h5py.File('../watershed/znn_merged.hdf5', "w" )
dset = f.create_dataset('/main', tuple(output_size) , chunks=tuple(chunk_size) , compression="gzip")

zabs = 0 
for z_znn in range(max_z+1):
	yabs = 0
	for y_znn in range(max_y+1):
		xabs = 0
		for x_znn in range(max_x+1):

			chunk_dir = 'z{0}-y{1}-x{2}'.format(z_znn,y_znn,x_znn)
			#Load znn chunks and concatenate it in one affinity, we assume this can fit in memory
			#If it doesn't we should make znn chunks smaller
			znn_chunk_size = numpy.fromfile('../znn/data/{0}/output/stage21.size'.format(chunk_dir), dtype='uint32')[::-1]
			znn_chunk_affinity =  numpy.fromfile('../znn/data/{0}/output/stage21'.format(chunk_dir), dtype='double').reshape(znn_chunk_size)

			print chunk_dir , ' merged'
			dset[:, zabs:zabs+znn_chunk_size[1], yabs:yabs+znn_chunk_size[2], xabs:xabs+znn_chunk_size[3]] = znn_chunk_affinity

			xabs = xabs+znn_chunk_size[3] - 1
		yabs = yabs+znn_chunk_size[2] - 1
	zabs = zabs+znn_chunk_size[1] - 1

print dset.shape

f.close()
