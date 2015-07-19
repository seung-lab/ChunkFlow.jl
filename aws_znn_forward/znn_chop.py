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

def prepare_cube(z1,z2,y1,y2,x1,x2):
    # extract cube in large volume
    f = h5py.File(gznn_raw_chann_fname)
    vol = np.asarray( f['/main'][z1:z2,y1:y2,x1:x2] )
    f.close
    
    # save the cube
    f = h5py.File( gshared_tmp+'cube_X{}-{}_Y{}-{}_Z{}-{}.h5'.format(x1,x2,y1,y2,z1,z2) )
    f.create_dataset('/main', data=vol, dtype='double')
    f.close()

def prepare_batch_script():
    print "prepare batch script..."
    # get the volume shape
    fa = h5py.File( gaffin_file )
    aff_size = np.asarray(fa['/main'].shape)
    print aff_size
    fa.close()
    
    if shutil.os.path.exists( gznn_batch_script_name ):
        shutil.os.remove( gznn_batch_script_name )
    f = open(gznn_batch_script_name, 'a+')
    f.write("#!/usr/bin/bash\n")
    
    # locate cubes and prepare file
    # list of cube coordinates
    cube_coords=[]
    for z in xrange(0, aff_size[1], gznn_blocksize[0]):
        for y in xrange(0, aff_size[2], gznn_blocksize[1]):
            for x in xrange(0, aff_size[3], gznn_blocksize[2]):
                z1, z2 = z,  min( aff_size[1], z+gznn_blocksize[0] )
                y1, y2 = y,  min( aff_size[2], y+gznn_blocksize[1] )
                x1, x2 = x,  min( aff_size[3], x+gznn_blocksize[2] )
                cube_coords.append((z1,z2,y1,y2,x1,x2))
                f.write("python " + gabspath + "aws_znn_forward/znn_forward.py {} {} {} {} {} {}\n".format( \                                                            
                               z1, z2,y1,y2,x1,x2))
                prepare_cube(z1,z2,y1,y2,x1,x2)
    f.close()
    
    # save the cube coordinates
    fc = h5py.File( gshared_tmp + 'cube_coordinates.h5' )
    fc.create_dataset('/main', data=cube_coords,dtype='uint32')
    fc.close()
        
def prepare_h5():
    print "prepare channel and affinity h5 files..."
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
    # remove the original file (to-do)
    os.remove()

def znn_chop():
    # clear and prepare shared temporary folder
    if os.path.exists(gshared_tmp):
	shutil.rmtree(gshared_tmp)
    os.mkdir(gshared_tmp)
    
    prepare_h5() 
    prepare_batch_script()
    
if __name__=="__main__":
    znn_chop()
#    shutil.os.remove( gtmp+"/*" )
