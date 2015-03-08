import os
import numpy as np
import h5py
import matplotlib.pylab as plt

#%% read hdf5
#f = h5py.File('../watershed/stage21.hdf5', 'r')
f = h5py.File('../watershed/znn_merged.hdf5', 'r')
affin = f['/main']

#%% prepare the folders
if not os.path.exists('../watershed/data'):
	os.makedirs('../watershed/data')
else:
	#For test
	import shutil
	shutil.rmtree('../watershed/data')
	os.makedirs('../watershed/data')

#%% metadata and size
metadata = np.array([32, 32, 1, 1, 1]).astype('int32')
#metadata = metadata[::-1]
#metadata = np.asfortranarray(metadata)
metadata.tofile('../watershed/data/input.metadata')

size = np.asarray( affin.shape[1:], dtype='int32' )
size = size[::-1]
#size = np.asfortranarray(size)
size.tofile('../watershed/data/input.chunksizes')

affin = np.asarray(affin, dtype='single')
ffin = np.reshape( affin, np.append(3, size[::-1]) )
affin = np.transpose(affin, (0,1,3,2))
affin.tofile('../watershed/data/input.affinity.data')
f.close()

#%% run watershed
os.makedirs('../watershed/data/input.chunks')
os.makedirs('../watershed/data/input.chunks/{0}/{1}/{2}'.format(0,0,0))

print "run watershed ..."
os.system("../watershed/src/zi/watershed/main/bin/xxlws" + " --filename=../watershed/data/input"\
            + " --high=0.99" + " --low=0.25" + " --dust=400" + " --dust_low=0.3")


#%% check the chunk file
#os.system('python test_chunk.py')