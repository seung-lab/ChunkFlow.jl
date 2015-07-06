# -*- coding: utf-8 -*-
"""
Created on Thu Jul  2 16:18:18 2015

@author: jingpeng
"""
import emirt
import os
import shutil
import h5py
from global_vars import *

def prepare_config(fname):
    config = """[PATH]
config=network.spec
load={}
data=data.
save=./
hist=

[OPTIMIZE]
n_threads={}
force_fft=1
optimize_fft=0

[TRAIN]
test_range=1
outsz={},{},{}
softmax=0
mirroring=0

[SCAN]
cutoff=1
    """.format( gznn_netpath, gznn_threads, \
                gznn_outsz[2], gznn_outsz[1], gznn_outsz[0] )
    # write the config file
    f = open(fname, 'w')
    f.write(config)
    f.close()
    
    
def prepare_data_spec(fname, image_path, size, isaffinity=True, ):
    if isaffinity:
        offset=1
    else:
        offset=0
    data_spec="""[INPUT1]
path={}
ext=image
size={},{},{}
pptype=standard2D

[MASK1]
size={},{},{}
offset={},{},{}
pptype=one
ppargs={}
    """.format( image_path, size[2], size[1], size[0], \
                size[2]-offset, size[1]-offset, size[0]-offset,\
                offset, offset, offset, 2+offset )
    # write the spec file
    f = open(fname,'w')
    f.write(data_spec)
    f.close()

def prepare_shell(fname, general_config):
    shell = """#!/bin/bash
export LD_LIBRARY_PATH=LD_LIBRARY_PATH:"/opt/boost/lib"
{} --test_only=true --options="{}"
    """.format( gznn_bin, general_config )
    # write shell script
    f = open(fname, 'w')
    f.write( shell )
    f.close()

#%%
def znn_forward_batch( inv ):
    """
    run znn forward pass
    inv: input channel volume as numpy array
    net_fname: the network configuration file name
    """
    # make the temporary folder
    if os.path.exists( gznn_tmp ):
        shutil.rmtree( gznn_tmp )
    os.mkdir( gznn_tmp )
    # cp the network file
    shutil.copy(gznn_net_fname, gznn_tmp + "network.spec")

    # prepare the data 
    emirt.io.znn_img_save(inv, gznn_tmp + "data.1.image")
    # prepare the data spec file
    prepare_data_spec( gznn_tmp+"data.1.spec", "data.1", inv.shape, True)
    # prepare the general config file
    prepare_config(gznn_tmp + "general.config")
    # prepare shell file
    prepare_shell( gznn_tmp + "znn_test.sh", "general.config" )
    # run znn forward pass
    os.system("cd " + gznn_tmp + "; bash znn_test.sh")
    
    # read the output
    affv_x = emirt.io.znn_img_read(gznn_tmp + "out1.0")
    affv_y = emirt.io.znn_img_read(gznn_tmp + "out1.1")
    affv_z = emirt.io.znn_img_read(gznn_tmp + "out1.2")    
    return outv

#%% get data from big channel hdf5 file
def znn_forward(chann_fname, aff_fname, z1,z2,y1,y2,x1,x2):
    f = h5py.File( chann_fname, 'r' )
    cv = np.asarray( f['/main'][z1:z2, y1:y2, x1:x2] )
    f.close()
    affv = znn_forward_batch(cv)
    offset = (cv.shape - affv.shape[1:])/2
    f = h5py.File( aff_fname, 'a+' )
    f['/main'][ :,  z1:z2-2*offset[0],\
                    y1:y2-2*offset[1],\
                    x1:x2-2*offset[2]] = affv
    f.close()

if __name__ == "__main__":
    cv = emirt.io.znn_img_read( gznn_znnpath + "dataset/fish/data/batch91.image")
    outv = znn_forward_batch( cv )