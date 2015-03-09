# -*- coding: utf-8 -*-
"""
Created on Wed Mar  4 13:14:28 2015

@author: jingpeng
"""
import numpy as np
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
import sys
sys.path.append("/usr/people/jingpeng/libs/")
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