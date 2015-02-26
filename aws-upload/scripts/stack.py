import tifffile
import numpy

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

	def convertToHDF5(self, fov):

		#We need to crop a margin based on the field of view , which is in z,y,x dimensiones
		#And then save it as a hdf5 which omnify is able to read.
		pass

		