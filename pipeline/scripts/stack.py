import tifffile
import numpy
import h5py

from global_vars import *
import re
import os

class Stack:

	def __init__ (self):
			

		if not  os.path.isfile('../alignment/stack.hdf5'):
			self.convertToHDF5(crop= numpy.array([0, 0 , 0]) , outputPath='../alignment/stack.hdf5')

		f = h5py.File('../alignment/stack.hdf5', 'r')
		self.input = f['/main']
		self.shape =  numpy.asarray(self.input.shape)

		return

	def checkAxis(self, provided, real_min, real_max):

		provided_min = 0
		provided_max = 0

		if  isinstance(provided,slice):
			provided_min = provided.start
			provided_max = provided.stop
		elif isinstance(provided,int):
			provided_min = provided
			provided_max = provided + 1
		else:
			raise Exception('Unkown type of slice')

		if provided_min > provided_max:
			raise Exception('axis in reverse order')

		if provided_min == None:
			provided_min = real_min

		if provided_max == None:
			provided_max = real_max

		return provided_min, provided_max

	def __getitem__(self, slice):

		if len(slice) != 3:
			raise Exception('You should expecify z,y,x')

		z_min , z_max = self.checkAxis(slice[0], 0 , self.shape[0])
		y_min , y_max = self.checkAxis(slice[1], 0 , self.shape[1])
		x_min , x_max = self.checkAxis(slice[2], 0 , self.shape[2])

		return self.input[z_min:z_max, y_min:y_max, x_min:x_max].astype('double')	

	def convertToHDF5(self, outputPath ,crop = numpy.array([0, 0 , 0])):

		index = re.compile(r'(\d+)_?')
		def numberSort(filename):
			return index.split(filename)[1]

		self.filestack = list() 
		for folder in ('tiff',):
			path = '../alignment/{}/'.format(folder)
			for z_tif in sorted(os.listdir(path), key=numberSort):
				self.filestack.append(path+z_tif)

		# # #read the first one to figure out the size
		# # #We assume all z-planes has the same size
		plane_shape = numpy.array(tifffile.imread(self.filestack[0]).shape)
		self.shape = numpy.concatenate((numpy.array([len(self.filestack)]) ,plane_shape)) 

		z_min = crop[0]/2 ; z_max = self.shape[0] - crop[0]/2
		y_min = crop[1]/2 ; y_max = self.shape[1] - crop[1]/2
		x_min = crop[2]/2 ; x_max = self.shape[2] - crop[2]/2

		#Open hdf5 file, and specified chunck size
		f = h5py.File(outputPath, "w" )

		channel_size = 	self.shape - crop 
		chunk_size =  self.shape - crop
		chunk_size[0] = 1


		#Should we used compression="gzip" on this?
		dset = f.create_dataset('/main', tuple(channel_size) , chunks=tuple(chunk_size) , dtype=numpy.uint8)		

		zabs = 0
		print z_min , z_max
		for tiff in range(z_min , z_max):
			
			print zabs , self.filestack[tiff] 
			cropped = tifffile.imread(self.filestack[tiff])[y_min:y_max , x_min:x_max]

			#change dtype
			cropped = cropped.astype(numpy.uint8)

			#save the chunck
			dset[zabs, 0:y_max-y_min, 0:x_max-x_min] = cropped

			zabs += 1

		f.close()
		return

		
if __name__ == "__main__":

	#If you directly call this file create hdf5
	s = Stack()
	
	#Create cropped channel data for omnifying
	#if we divide the watershed output in many omnifiles
	#omnify.py will be responsable of doing it
	#s.convertToHDF5(crop = fov_effective-1, outputPath='../omnify/channel.hdf5')

