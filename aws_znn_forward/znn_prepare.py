# -*- coding: utf-8 -*-
"""
Created on Mon Jul  6 14:22:18 2015

@author: jingpeng
"""
import h5py
import shutil
from global_vars import *

def prepare_batch_script( chann_fname ):
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
                z1 = z; z2 = min( sz[0], z+gznn_blocksize[0] )
                y1 = y; y2 = min( sz[1], y+gznn_blocksize[1] )
                x1 = x; x2 = min( sz[2], x+gznn_blocksize[2] )
                f.write("python ../aws_znn_forward/znn_forward.py {} {} {} {} {} {} {}\n".format( \
                                                            chann_fname,\
                                                            z1, z2,\
                                                            y1, y2,\
                                                            x1, x2))
    f.close()
    

def prepare_h5():
    # prepare the output affinity hdf5 file
    if ".image" in gznn_chann_fname:
        chann_fname = gtmp+"/znn_raw_chann.h5"
        if shutil.os.path.exists( chann_fname ):
            shutil.os.remove( chann_fname )
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
    if shutil.os.path.exists( gaffin_file ):
            shutil.os.remove( gaffin_file )
    fa = h5py.File( gaffin_file )
    fa.create_dataset('/main', shape=sz_affin, dtype='float32', chunks=True, compression="gzip")
    fa.close()
    # create the channel hdf5 file
    if shutil.os.path.exists( gchann_file ):
            shutil.os.remove( gchann_file )
    fc2 = h5py.File( gchann_file )
    fc2.create_dataset('/main', shape=sz_affin[1:4], dtype="float32" )
    chann2 = fc2['/main']
    # in case the channel data is huge, copy layer by layer
    for z in xrange( sz_affin[1] ):
        chann2[z,:,:] = raw_chann[z+offset[0], offset[1]:-offset[1], offset[2]:-offset[2]]
        
    fc.close()
    fc2.close()
    return chann_fname

def znn_prepare():
    chann_fname = prepare_h5() 
    prepare_batch_script( chann_fname )
    
if __name__=="__main__":
    znn_prepare()
#    shutil.os.remove( gtmp+"/*" )