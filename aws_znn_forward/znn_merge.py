# -*- coding: utf-8 -*-
"""
Created on Sun Jul 19 10:22:38 2015

@author: jingpeng
"""
import shutil
import h5py
from global_vars import *

def get_fov():
    if len(gznn_fovs)==1:
        return gznn_fovs[0]
    elif len(gznn_fovs)==2:
        return gznn_fovs[0]+gznn_fovs[1]-1
    else:
        raise NameError("do not support this FoV parameter!")

def znn_merge():
    """
    merge the cubes in an affinity h5 file
    """
    # prepare affinity file
    f = h5py.File(gchann_file)
    shape2 = f['/main'].shape
    f.close()
    fov = get_fov()
    offset = (fov - 1)/2
    sz_affin = np.hstack((3,shape2))
    # create the affinity hdf5 file
    if shutil.os.path.exists( gaffin_file ):
            shutil.os.remove( gaffin_file )
    fa = h5py.File( gaffin_file )
    fa.create_dataset('/main', shape=sz_affin, dtype='float32', chunks=True, compression="gzip")
    fa.close()
    
    # merge the cubes in affinity file
    # read coordinates
    f = h5py.File(gshared_tmp + 'cube_coordinates.h5')
    coords = list( f['/main'] )
    f.close()
    # merge the cubes
    for c in coords:
        z1,z2,y1,y2,x1,x2 = c
        # read the cube
        fc = h5py.File( gshared_tmp+'affin_X{}-{}_Y{}-{}_Z{}-{}.h5'.format(x1,x2,y1,y2,z1,z2) )
        vol = np.asarray( fc['/main'] )
        fc.close()
        # save in global affinity file
        fa = h5py.File( gaffin_file )
        fa['/main'][:,z1:z2,y1:y2,x1,x2] = vol
        fa.close()
        
