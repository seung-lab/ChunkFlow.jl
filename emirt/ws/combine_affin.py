# -*- coding: utf-8 -*-
"""
Created on Fri Feb  6 11:30:27 2015
combine affin
@author: jingpeng
"""
import numpy as np

#%% parameters
Dir = '/usr/people/jingpeng/seungmount/research/Ignacio/aws-znn/aws-upload/data/z0-y0-x0/output/'
fname = 'stage21.'
dst_dir = '/usr/people/jingpeng/'
dst_fname= 'stage21'


#%% read volume
v0 = np.fromfile( Dir + fname + '0', dtype='double' )
v1 = np.fromfile( Dir + fname + '1', dtype='double' )
v2 = np.fromfile( Dir + fname + '2', dtype='double' )
# size
sz0 = np.fromfile( Dir + fname + '0.size', dtype='uint32' )
sz1 = np.fromfile( Dir + fname + '1.size', dtype='uint32' )
sz2 = np.fromfile( Dir + fname + '2.size', dtype='uint32' )

# transpose
v0 = np.transpose(v0.reshape(sz0, order='F'))
v1 = np.transpose(v1.reshape(sz1, order='F'))
v2 = np.transpose(v2.reshape(sz2, order='F'))

#%% combine and write
affin = np.concatenate((v0[None,...],v1[None,...],v2[None,...]), axis=0)
affin.tofile( dst_dir + dst_fname + '.affin.raw')

sz0.tofile( dst_dir + dst_fname + '.affin.raw.size')

#%% write as a hdf5 file
import h5py
h5filename = dst_dir +  dst_fname + 'hdf5'
f = h5py.File(h5filename, 'w')
f.create_dataset('/main', data=affin, dtype='double')
f.close()

#%% visualization
import neupy.show
#neupy.show.imshow(v0[20,:,:])
neupy.show.imshow(affin[1,20,:,:])