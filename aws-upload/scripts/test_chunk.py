# -*- coding: utf-8 -*-
"""
Created on Wed Mar  4 13:14:28 2015

@author: jingpeng
"""
import numpy as np
import sys
sys.path.append("/usr/people/jingpeng/libs/")
import neupy
#import sys
#sys.path.append('./fortranfile-0.2.1/')
#import fortranfile
#%% parameters
filename = '../watershed/data/input'
#filename = '/usr/people/jingpeng/seungmount/research/Jingpeng/01_workspace/03_watershed/WS_scripts/temp/wstemp'

chunkidz = 0
chunkidy = 1
chunkidx = 1

#%% read the chunk
# number of chunks in the xyz direction
chunkNum = np.fromfile(filename+".metadata", dtype='uint32')[2:5][::-1]
# chunk sizes
chunksizes = np.fromfile(filename+".chunksizes", dtype='uint32').reshape(-1,3)[:,::-1]
sze = chunksizes[ chunkidz+chunkidy*chunkNum[0]+ chunkidx*chunkNum[0]*chunkNum[1], : ]

fname = filename + '.chunks/' + str(chunkidx) + '/' + str(chunkidy) \
                    + '/' + str(chunkidz) + '/.seg'
chk = np.reshape( np.fromfile(fname,  dtype='uint32' ), sze)

#%% show chunk
import neupy.show
neupy.show.random_color_show( chk[5,:,:] )

#%%
# the dend and dend values
dendValues = np.fromfile( filename + '.dend_values', dtype='single' )
dend = np.fromfile( filename + '.dend_pairs', dtype = 'uint32' )
dend = dend.reshape((2, len(dendValues)))    

#%% test the affinity graph
#affin = np.fromfile(filename + ".affinity.data", dtype='single')
#affin = np.reshape(affin, np.append(3, sze))
#affin = np.transpose(affin, (0,1,3,2))
#neupy.show.imshow( affin[1,6,:,:] )

#%% test dend and dend values
dendValues = np.fromfile( filename + '.dend_values', dtype='single' )
dend = np.fromfile( filename + '.dend_pairs', dtype = 'uint32' )
dend = dend.reshape((len(dendValues), 2)).transpose()

#%% test the raw image
import neupy
reload(neupy)
import h5py
#f = h5py.File('../watershed/stack.chann.hdf5')
#f = h5py.File('/usr/people/jingpeng/seungmount/research/Jingpeng/01_workspace/08_piriform_cortex/znn_merged_W1234_crop.affin.hdf5')
f = h5py.File('/usr/people/jingpeng/seungmount/research/Jingpeng/01_workspace/08_piriform_cortex/stack_W1234_crop.chann.hdf5')
chann = np.asarray(f['/main'])[:,:,:]
neupy.show.vol_slider(chann, cmap='gray')
f.close()


#%% test the big channel data
import h5py
#f = h5py.File('/usr/people/jingpeng/seungmount/research/Ignacio/w0-4/omnify/stack_W1234.chann.hdf5')
f = h5py.File('/usr/people/jingpeng/seungmount/research/Jingpeng/01_workspace/08_piriform_cortex/stack_W1234_crop.chann.hdf5')
im = f['/main'][0,:,:]# Z 4
import matplotlib.pylab as plt
plt.subplot(121)
plt.imshow(im, cmap='gray')
f.close()

plt.subplot(122)
plt.figure
#f = h5py.File('/usr/people/jingpeng/seungmount/research/Ignacio/w0-4/omnify/znn_merged_W1234.hdf5')
f = h5py.File('/usr/people/jingpeng/seungmount/research/Jingpeng/01_workspace/08_piriform_cortex/znn_merged_W1234_crop.affin.hdf5')
seg = f['/main'][0,0,:,:]# Z ,-5
plt.imshow(seg)
#import sys
#sys.path.append("/usr/people/jingpeng/libs/")
#import neupy
#neupy.show.random_color_show(seg)
f.close()

