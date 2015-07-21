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
#import subprocess
import os

def get_fov():
    if len(gznn_fovs)==1:
        return gznn_fovs[0]
    elif len(gznn_fovs)==2:
        return gznn_fovs[0]+gznn_fovs[1]-1
    else:
        raise NameError("do not support this FoV parameter!")
        
def prepare_cube(z1,z2,y1,y2,x1,x2):
    # extract cube in large volume
    # get field of view
    fov = get_fov()

    f = h5py.File(gznn_raw_chann_fname)
    vol = np.asarray( f['/main'][z1:z2+fov[0]-1,y1:y2+fov[1]-1,x1:x2+fov[2]-1] )
    f.close
    

    print vol.shape

    # save the cube
    f = h5py.File( gtmp+'chann_Z{}-{}_Y{}-{}_X{}-{}.h5'.format(z1,z2,y1,y2,x1,x2) )
    f.create_dataset('/main', data=vol, dtype='double')
    f.close()

def prepare_batch_script():
    print "prepare batch script..."
    # get the volume shape
    fc = h5py.File( gchann_file )
    size2 = np.asarray(fc['/main'].shape)
    fc.close()
    
    if shutil.os.path.exists( gznn_batch_script_name ):
        shutil.os.remove( gznn_batch_script_name )
    f = open(gznn_batch_script_name, 'a+')
    f.write("#!/usr/bin/bash\n")
    
    # locate cubes and prepare file
    # list of cube coordinates
    cube_coords=[]
    for z in xrange(0, size2[0], gznn_blocksize[0]):
        for y in xrange(0, size2[1], gznn_blocksize[1]):
            for x in xrange(0, size2[2], gznn_blocksize[2]):
                z1, z2 = z,  min( size2[0], z+gznn_blocksize[0] )
                y1, y2 = y,  min( size2[1], y+gznn_blocksize[1] )
                x1, x2 = x,  min( size2[2], x+gznn_blocksize[2] )
                cube_coords.append((z1,z2,y1,y2,x1,x2))
                f.write("python " + gabspath + "znn_forward/znn_forward.py {} {} {} {} {} {}\n".format(z1, z2,y1,y2,x1,x2))
                prepare_cube(z1,z2,y1,y2,x1,x2)
    f.close()
    
    # save the cube coordinates
    fc = h5py.File( gtmp + 'cube_coordinates.h5' )
    fc.create_dataset('/main', data=cube_coords,dtype='uint32')
    fc.close()
        
def prepare_h5():
    print "prepare channel h5 files..."
    # copy data from S3 to EBS volume
    raw_chann_tif = gznn_raw_chann_fname.replace(".h5", ".tif")
    if "s3" in gznn_chann_origin and not shutil.os.path.exists(raw_chann_tif):
        os.system("aws s3 cp " + gznn_chann_origin + " " + raw_chann_tif)
    elif not shutil.os.path.exists(raw_chann_tif):
        os.system("cp "+ gznn_chann_origin + " " + raw_chann_tif)
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
    
    # crop raw channel volume h5 file
    fc = h5py.File( gznn_raw_chann_fname )
    raw_chann = fc['/main']
    sz_chann = raw_chann.shape
    # get croped channel volume size
    fov = get_fov()
    offset = (fov - 1)/2
    crop_shape = sz_chann - fov+1
 
    # create the channel hdf5 file
    if shutil.os.path.exists( gchann_file ):
            shutil.os.remove( gchann_file )
    fc2 = h5py.File( gchann_file )
    fc2.create_dataset('/main', shape=crop_shape, dtype="float32" )
    chann2 = fc2['/main']
    # in case the channel data is huge, copy layer by layer
    for z in xrange( crop_shape[0] ):
        sec = raw_chann[z+offset[0], offset[1]:-offset[1], offset[2]:-offset[2]]
        # normalize for omni
        chann2[z,:,:] = emirt.volume_util.norm( np.asarray(sec) )     
    fc.close()
    fc2.close()
    
def znn_chop():
    # clear and prepare shared temporary folder
    if os.path.exists(gtmp):
	shutil.rmtree(gtmp)
    os.mkdir(gtmp)
    
    prepare_h5() 
    prepare_batch_script()
    
    # remove the original file
    os.remove( gznn_raw_chann_fname )
    
if __name__=="__main__":
    znn_chop()
