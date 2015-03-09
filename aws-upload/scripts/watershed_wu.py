import os
import numpy as np
import h5py

import sys
sys.path.append('fortranfile-0.2.1')
import fortranfile
#%% parameters
znn_merged_h5file = '../watershed/znn_merged.hdf5'

# step 
width = np.array([500, 500, 500])

temp_path = '../watershed/data/'

#%% prepare the folders
if os.path.exists(temp_path):
    import shutil
    shutil.rmtree(temp_path)

os.makedirs(temp_path + 'input.chunks/')

#%% read hdf5
f = h5py.File(znn_merged_h5file, 'r')
affin = f['/main']
#affin = np.transpose(affin, (0,1,3,2))

s = np.array(affin.shape)[1:]

#Faffin = fortranfile.FortranFile(temp_path + 'input.affinity.data', mode = 'w')
fa = open(temp_path + 'input.affinity.data', mode='w+')

chunkSizes = []
chunkid = 0
for cidx, x in enumerate(range(0, s[2], width[2]) ):
    for cidy, y in enumerate(range(0, s[1], width[1])):
        for cidz, z in enumerate( range(0, s[0], width[0]) ):
           chunkid += 1
           cfrom = np.maximum( np.array([z,y,x])-1, np.array([0,0,0]))
           cto = np.minimum(np.array([z,y,x]) + width + 1, s)
           size = cto - cfrom 
           chunkSizes.append( size[::-1] )
           
           part = affin[:,cfrom[0]:cto[0], cfrom[1]:cto[1], cfrom[2]:cto[2]]
           part = np.transpose(part, (0,1,3,2))
           part.tofile(fa)
           
           os.makedirs(temp_path + 'input.chunks/{0}/{1}/{2}'.format(cidx,cidy,cidz))

# close the files
f.close()
fa.close()

# metadata and size
metadata = np.array([32, 32, cidx+1, cidy+1, cidz+1]).astype('int32')
metadata.tofile(temp_path + 'input.metadata')

chunkSizes = np.array( chunkSizes, dtype='uint32' )
chunkSizes.tofile(temp_path + 'input.chunksizes')

#%% run watershed
print "run watershed ..."
os.system("../watershed/src/zi/watershed/main/bin/xxlws" + " --filename=../watershed/data/input"\
            + " --high=0.99" + " --low=0.25" + " --dust=400" + " --dust_low=0.3")
