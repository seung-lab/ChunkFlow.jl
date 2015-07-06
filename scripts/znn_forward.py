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
def znn_forward_batch( inv, isaff ):
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
    prepare_data_spec( gznn_tmp+"data.1.spec", "data.1", inv.shape, isaff)
    # prepare the general config file
    prepare_config(gznn_tmp + "general.config")
    # prepare shell file
    prepare_shell( gznn_tmp + "znn_test.sh", "general.config" )
    # run znn forward pass
    os.system("cd " + gznn_tmp + "; bash znn_test.sh")
    
    # read the output
    out_fname = gznn_tmp + "out1."
    if os.path.exists( out_fname + "2" ):
        # affinity output
        sz = np.fromfile(out_fname + "1.size", dtype='uint32')[:3]
        affv = np.zeros( np.hstack((3,sz)), dtype="float64" )
        affv[0,:,:,:] = emirt.io.znn_img_read(out_fname + "0")
        affv[1,:,:,:] = emirt.io.znn_img_read(out_fname + "1")
        affv[2,:,:,:] = emirt.io.znn_img_read(out_fname + "2") 
        return affv
    else:
        # boundary map output
        return emirt.io.znn_img_read(out_fname + "1")

#%% 
def znn_forward(z1,z2,y1,y2,x1,x2):
    """
    get data from big channel hdf5 file
    the coordinate range is in the affinity map
    """
    offset = (gznn_fov - 1)/2
    f = h5py.File( graw_chann_fname, 'r' )
    cv = np.asarray( f['/main'][z1:z2 + 2*offset[0], \
                                y1:y2 + 2*offset[1], \
                                x1:x2 + 2*offset[2]] )
    f.close()
    affv = znn_forward_batch(cv, True)
    
    f = h5py.File( gaffin_file )
    f['/main'][ :,  z1:z2, y1:y2, x1:x2] = affv
    f.close()

if __name__ == "__main__":
    # to-do : parameter parser
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("z1", help="z start", type=int)
    parser.add_argument("z2", help="z end  ", type=int)
    parser.add_argument("y1", help="y start", type=int)
    parser.add_argument("y2", help="y end  ", type=int)
    parser.add_argument("x1", help="x start", type=int)
    parser.add_argument("x2", help="x end  ", type=int)
    args = parser.parse_args()
    znn_forward(    args.z1, args.z2, \
                    args.y1, args.y2, \
                    args.x1, args.x2)
    
    
    #%%
#    cv = emirt.io.znn_img_read( gznn_znnpath + "dataset/fish/data/batch91.image")
#    outv = znn_forward_batch( cv, True )
#    
#    # crop the channel
#    offset = (cv.shape-outv.shape[1:])/2
#    cv = cv[offset[0]:-offset[0],\
#            offset[1]:-offset[1],\
#            offset[2]:-offset[2]]
#    # write the channel and affinity
#    f = h5py.File( gchann_file )
#    f.create_dataset('/main', data=cv, dtype="float32")
#    f.close()
#    f = h5py.File( gaffin_file )
#    f.create_dataset('/main', data=outv, dtype="float32")
#    f.close()
#    