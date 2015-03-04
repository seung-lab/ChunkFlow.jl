import tifffile
import numpy
import h5py

from node_specification import *
import re
import os

class Stack:

	def __init__ (self):
		
		self.filestack = list() 

		base = '/usr/people/it2/seungmount/research/tommy/S2_renders/'
		folders = ('150218_S2-W001_elastic_01_3600_3600/' , '150224_S2-W002_elastic_01_3600_3600/' , '150303_S2-W003_elastic_01_3600_3600/')

		index = re.compile(r'(\d+)_')
		def numberSort(filename):
			return index.split(filename)[1]

		for folder in folders:
			path = base + folder
			for z_tif in sorted(os.listdir(path), key=numberSort):

				self.filestack.append(path+z_tif)


		print self.filestack


		#I'm loading everything in ram because is an small stack
		#Otherwise never do it 
		#self.input = tifffile.imread('../../alignment/stack.tif')

		#The maximun of a tiff is 4gb, if our dataset is larger we should create one tiff
		#Per z-plane.
		#You could use this constructor to get the stack dimensions.
		#self.dims =  numpy.asarray(self.input.shape)

		return

	def getStackDimensions(self):

		return self.dims

	def getChunk(self, z_max, z_min, y_max, y_min, x_max, x_min):

		#When we use a large stack, there will be some more complex logic here to retrieve the chunck
		#because we will load the required z-planes as needed.

		return self.input[z_min:z_max, y_min:y_max, x_min:x_max].astype('double')

	def convertToHDF5(self, fov = numpy.array([8, 172 ,172])):

		#We need to crop a margin based on the field of view , which is in z,y,x dimensiones
		#And then save it as a hdf5 which omnify is able to read.

		#this implementation required to load everything in ram
		dims = self.getStackDimensions()

		z_min = fov[0]/2 ; z_max = dims[0] - fov[0]/2
		y_min = fov[1]/2 ; y_max = dims[1] - fov[1]/2
		x_min = fov[2]/2 ; x_max = dims[2] - fov[2]/2


		#Divide the input in the z-dimension and process one chunk at the time
		z_plane_size = (x_max - x_min) * (y_max - y_min) * 8 #bytes for each double
		divs = numpy.ceil(z_max / (memory / z_plane_size)).astype(int) 
		
		#Open hdf5 file, and specified chunck size
		f = h5py.File('../omnify/stack.chann.hdf5', "w" )

		channel_size = 	dims - fov 
		chunk_size =  dims - fov 
		chunk_size[0] = chunk_size[0]/divs

		#Should we used compression="gzip" on this?
		dset = f.create_dataset('/main', tuple(channel_size) , chunks=tuple(chunk_size) , compression="gzip")		

		for z_chunk_max in numpy.linspace(z_min, z_max.astype(int) , divs +1):
			z_chunk_max = z_chunk_max.astype(int)

			if z_chunk_max == z_min:
				z_chunk_min = z_min
				continue

			#print z_chunk_max, z_chunk_min 
			cropped = self.getChunk(z_chunk_max, z_chunk_min, y_max, y_min, x_max, x_min)
			#Normalize and change dtype
			cropped = cropped.astype('float32')
			cropped = ( cropped - cropped.min()) / (cropped.max() - cropped.min())

			#save the chunck
			dset[0:z_chunk_max-z_chunk_min, 0:y_max-y_min, 0:x_max-x_min] = cropped

			#For next loop
			z_chunk_min = z_chunk_max


		f.close()
		return

		
if __name__ == "__main__":

	#If you directly call this file create hdf5
	s = Stack()
	#s.convertToHDF5()

