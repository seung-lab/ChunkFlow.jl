# -*- coding: utf-8 -*-
"""
Created on Mon Jul  6 14:22:18 2015

@author: jingpeng
"""
import h5py
import shutil
from global_vars import *

def prepare_batch_script():
    # get the volume shape
    fa = h5py.File( gaffin_file )
    sz = fa['/main'].shape
    fa.close()
    
    if shutil.os.path.exists( gznn_batch_script_name ):
        shutil.os.remove( gznn_batch_script_name )
    f = open(gznn_batch_script_name, 'a+')
    f.write("#!/usr/bin/bash\n")
    for z in xrange(0, sz[0], gznn_blocksize[0]):
        for y in xrange(0, sz[1], gznn_blocksize[1]):
            for x in xrange(0, sz[2], gznn_blocksize[2]):
                f.write("python znn_forward.py {} {} {} {} {} {}\n".format(   z, z+gznn_blocksize[0],\
                                                                            y, y+gznn_blocksize[1],\
                                                                            x, x+gznn_blocksize[2]))
    f.close()
    

def prepare_h5():
    # prepare the output affinity hdf5 file
    if ".image" in gznn_chann_fname:
        chann_fname = gtmp+"/znn_raw_chann.h5"
        import emirt
        vc = emirt.io.znn_img_read( gznn_chann_fname )
        ft = h5py.File( chann_fname )
        ft.create_dataset('/main', data=vc, dtype='float32')
        ft.close()
        
    else:
        chann_fname = gznn_chann_fname
        
    fc = h5py.File( chann_fname )
    raw_chann = fc['/main']
    sz_chann = raw_chann.shape
    
    offset = (gznn_fov - 1)/2
    sz_affin = sz_chann - 2*offset
    sz_affin = np.hstack((3,sz_affin))
    # create the affinity hdf5 file
    fa = h5py.File( gaffin_file )
    fa.create_dataset('/main', shape=sz_affin, dtype='float32', chunks=True, compression="gzip")
    fa.close()
    # create the channel hdf5 file
    fc2 = h5py.File( gchann_file )
    fc2.create_dataset('/main', shape=sz_affin[1:4], dtype="float32" )
    chann2 = fc2['/main']
    # in case the channel data is huge, copy layer by layer
    for z in xrange( sz_affin[1] ):
        chann2[z,:,:] = raw_chann[z+offset, offset:-offset, offset:-offset]
        
    fc.close()
    fc2.close()

def znn_prepare():
    prepare_h5() 
    prepare_batch_script()
    
if __name__=="__main__":
    znn_prepare()