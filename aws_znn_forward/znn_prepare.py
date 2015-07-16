# -*- coding: utf-8 -*-
"""
Created on Mon Jul  6 14:22:18 2015

@author: jingpeng
"""
import sys
sys.path.append("..")
import h5py
import shutil
from global_vars import *
import emirt

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
                z1 = z; z2 = min( sz[0], z+gznn_blocksize[0] )
                y1 = y; y2 = min( sz[1], y+gznn_blocksize[1] )
                x1 = x; x2 = min( sz[2], x+gznn_blocksize[2] )
                f.write("python ../aws_znn_forward/znn_forward.py {} {} {} {} {} {} {}\n".format( \
                                                            gznn_raw_chann_fname,\
                                                            z1, z2,\
                                                            y1, y2,\
                                                            x1, x2))
    f.close()

def get_fov():
    if len(gznn_fovs)==1:
        return gznn_fovs[0]
    elif len(gznn_fovs)==2:
        return gznn_fovs[0]+gznn_fovs[1]-1
    else:
        raise NameError("do not support this FoV parameter!")
        
def prepare_h5():
    # copy data from S3 to EBS volume
    raw_chann_tif = gznn_raw_chann_fname.replace(".h5", ".tif")
    if gisaws and not shutil.os.path.exists(raw_chann_tif):
        os.system("aws s3 cp " + gznn_chann_s3fname + " " + raw_chann_tif)
    # prepare the raw channel data 
    if ".image" in gznn_raw_chann_fname:
        if shutil.os.path.exists( gznn_raw_chann_fname ):
            shutil.os.remove( gznn_raw_chann_fname )
        vc = emirt.io.znn_img_read( gznn_raw_chann_fname )
        ft = h5py.File( gznn_raw_chann_fname )
        ft.create_dataset('/main', data=vc, dtype='float32')
        ft.close()
    elif ".tif" in raw_chann_tif:
        vol = emirt.io.imread( raw_chann_tif )
        emirt.io.imsave(vol, gznn_raw_chann_fname)            
    elif ".h5" in gznn_raw_chann_fname:
        print "h5 file, do not need to transform!"
    else:
        raise NameError('unknown channel data format!')
    
    # crop raw channel volume and prepare affinity h5 file
    fc = h5py.File( gznn_raw_chann_fname )
    raw_chann = fc['/main']
    sz_chann = raw_chann.shape
    
    fov = get_fov()
    offset = (fov - 1)/2
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
        sec = raw_chann[z+offset[0], offset[1]:-offset[1], offset[2]:-offset[2]]
        # normalize for omni
        chann2[z,:,:] = emirt.volume_util.norm( sec )
        
    fc.close()
    fc2.close()

def znn_prepare():
    if not os.path.exists(gtmp):
	os.mkdir(gtmp)
    prepare_h5() 
    prepare_batch_script()
    
if __name__=="__main__":
    znn_prepare()
#    shutil.os.remove( gtmp+"/*" )
