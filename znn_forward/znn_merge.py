#!/usr/bin/env python
__doc__ = """
rundd forward pass using znn

wrape ZNN as a function to process numpy array. 
This module could be replaced to run ZNN V4

Jingpeng Wu <jingpeng.wu@gmail.com>, 2015
"""
import shutil
import h5py
from global_vars import *

def znn_merge():
    """
    merge the cubes in an affinity h5 file
    """
    # prepare affinity file
    print "prepare affinity file..."
    f = h5py.File(gchann_file, 'r')
    shape2 = f['/main'].shape
    f.close()
    sz_affin = np.hstack((3,shape2))
    # create the affinity hdf5 file
    if shutil.os.path.exists( gaffin_file ):
            shutil.os.remove( gaffin_file )
    fa = h5py.File( gaffin_file )
    fa.create_dataset('/main', shape=sz_affin, dtype='float32', chunks=True, compression="gzip")
    
    # merge the cubes in affinity file
    print "merge cubes..."
    # read coordinates
    f = h5py.File(gtmp + 'cube_coordinates.h5')
    coords = list( f['/main'] )
    f.close()
    print coords
    # merge the cubes
    for c in coords:
        print c
        z1,z2,y1,y2,x1,x2 = c
        # read the cube
        fc = h5py.File( gtmp+'affin_Z{}-{}_Y{}-{}_X{}-{}.h5'.format(z1,z2,y1,y2,x1,x2) )
        vaff = np.asarray( fc['/main'] )
        fc.close()
        # save in global affinity file
        fa['/main'][:,z1:z2,y1:y2,x1:x2] = vaff
      
    fa.close()


if __name__ == "__main__":
    znn_merge() 
