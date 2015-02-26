import tifffile
import numpy
import h5py

class Stack:

	def __init__ (self):
		
		#I'm loading everything in ram because is an small stack
		#Otherwise never do it
		self.input = tifffile.imread('../../alignment/stack.tif')

		#The maximun of a tiff is 4gb, if our dataset is larger we should create one tiff
		#Per z-plane.
		#You could use this constructor to get the stack dimensions.
		self.dims =  numpy.asarray(self.input.shape)

		return

	def getStackDimensions(self):

		return self.dims

	def getChunk(self, z_max, z_min, y_max, y_min, x_max, x_min):

		#When we use a large stack, there will be some more complex logic here to retrieve the chunck
		#because we will load the required z-planes as needed.

		return self.input[z_min:z_max, y_min:y_max, x_min:x_max]

	def convertToHDF5(self, fov = numpy.array([8, 172 ,172])):

		#We need to crop a margin based on the field of view , which is in z,y,x dimensiones
		#And then save it as a hdf5 which omnify is able to read.

		#this implementation required to load everything in ram
		dims = self.getStackDimensions()

		z_min = fov[0]/2 ; z_max = dims[0] - fov[0]/2
		y_min = fov[1]/2 ; y_max = dims[1] - fov[1]/2
		x_min = fov[2]/2 ; x_max = dims[2] - fov[2]/2

		cropped = self.getChunk(z_max, z_min, y_max, y_min, x_max, x_min)

		#Normalize and change dtype
		cropped = cropped.astype('float32')
		cropped = ( cropped - cropped.min()) / (cropped.max() - cropped.min())

		f = h5py.File('../omnify/stack.chann.hdf5', "w" )
		f.create_dataset('/main', data=cropped)
		f.close()
		return

		
if __name__ == "__main__":

	#If you directly call this file create hdf5
	s = Stack()
	s.convertToHDF5()

