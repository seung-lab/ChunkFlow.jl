#!/usr/bin/env python
__doc__ = """
run forward pass using znn

wrape ZNN as a function to process numpy array. 
This module could be replaced to run ZNN V4

Jingpeng Wu <jingpeng.wu@gmail.com>, 2015
"""
# configure sys path
import sys
import os
current_path = os.path.dirname(os.path.abspath(__file__)) + "/../"
if current_path not in sys.path:
    sys.path.append(current_path)

import emirt
import shutil
import h5py
from global_vars import *

def prepare_config(fname, netname, isaff ):
    net_spec = gznn + "networks/" + netname + ".spec"
    net_file = gznn + "experiments/" + netname + "/network/"
    if isaff:
        dp_type="affinity"
    else:
        dp_type="volume"
        
    config = """
[PATH]
config={}
load={}
data=data.
save={}

[OPTIMIZE]
n_threads={}
force_fft=1
optimize_fft=0

[TRAIN]
test_range=1
outsz={},{},{}
dp_type={}
softmax=0
mirroring=0

[SCAN]
cutoff=1
    """.format( net_spec, net_file, gznn_tmp, gznn_threads, \
                gznn_outsz[2], gznn_outsz[1], gznn_outsz[0], dp_type )
    # write the config file
    f = open(fname, 'w')
    f.write(config)
    f.close()
    
    
def prepare_data_spec(fname, image_path, size, stgid, isaff, ):
    if isaff:
        offset=1
    else:
        offset=0
    INPUT1="""
[INPUT1]
path={}
ext=image
size={},{},{}
pptype=standard2D
    """.format(image_path, size[2], size[1], size[0])
    
    if stgid == 0:
        INPUT2 = ""
    elif (stgid == 1) and len(gznn_net_names)==2:
        INPUT2="""
[INPUT2]
path={}
size={},{},{}
offset={},{},{}
pptype=transform
ppargs=0,1
        """.format(gznn_tmp+"out1.1", \
        size[2]-(gznn_fovs[0][2]-1),\
        size[1]-(gznn_fovs[0][1]-1),\
        size[0]-(gznn_fovs[0][0]-1),\
	(gznn_fovs[0][2]-1)/2,\
	(gznn_fovs[0][1]-1)/2,\
	(gznn_fovs[0][0]-1)/2)
    else:
        raise NameError("stage setting is wrong!")
        
    MASK1 = """
[MASK1]
size={},{},{}
offset={},{},{}
pptype=one
ppargs={}
    """.format( size[2]-offset, size[1]-offset, size[0]-offset,\
                offset, offset, offset, 2+offset )
    # write the spec file
    f = open(fname,'w')
    f.write(INPUT1)
    f.write(INPUT2)
    f.write(MASK1)
    f.close()

def prepare_shell(fname, general_config):
    shell = """#!/bin/bash
export LD_LIBRARY_PATH=LD_LIBRARY_PATH:"{}"
{} --test_only=true --options="{}"
    """.format( gznn_boost_lib, gznn_bin, general_config )
    # write shell script
    f = open(fname, 'w')
    f.write( shell )
    f.close()

#%%
def znn_forward_cube( inv ):
    """
    run znn forward pass
    inv: input channel volume as numpy array
    net_fname: the network configuration file name
    """
    # make the temporary folder
    if os.path.exists( gznn_tmp ):
        shutil.rmtree( gznn_tmp )
    os.mkdir( gznn_tmp )
    
    # first stage forward pass
    if len(gznn_net_names)==1:
        isaff=True
    elif len(gznn_net_names)==2:
        isaff=False
    else:
        raise NameError("do not support this net name parameter!")
        
    netname = gznn_net_names[0]
    # prepare the data 
    emirt.io.znn_img_save(inv, gznn_tmp + "data.1.image")
    # prepare the data spec file
    prepare_data_spec( gznn_tmp+"data.1.spec", gznn_tmp+"data.1", \
                        np.asarray(inv.shape), 0, isaff)
    # prepare the general config file
    prepare_config(gznn_tmp + "general.config", netname, isaff)
    # prepare shell file
    prepare_shell( gznn_tmp + "znn_forward.sh", "general.config" )
    # run znn forward pass
    os.system("cd " + gznn_tmp + "; bash znn_forward.sh")

    # second stage forward pass    
    if len(gznn_net_names)==2:
  	print "second stage.."
        isaff = True
        netname = gznn_net_names[1]
        # prepare the data spec file
        prepare_data_spec( gznn_tmp+"data.1.spec", gznn_tmp+"data.1", inv.shape-(gznn_fovs[0]-1), 1, isaff)
        # prepare the general config file
        prepare_config(gznn_tmp + "general.config", netname, isaff)
        # prepare shell file
        prepare_shell( gznn_tmp + "znn_forward.sh", "general.config" )
        # run znn forward pass
        os.system("cd " + gznn_tmp + "; bash znn_forward.sh")
        
    # read the output
    out_fname = gznn_tmp + "out1."
    if isaff and len(gznn_net_names)==2:
        # affinity output
        sz = np.fromfile(out_fname + "1.size", dtype='uint32')[::-1]
        affv = np.zeros( np.hstack((3,sz)), dtype="float64" )
        affv[0,:,:,:] = emirt.io.znn_img_read(out_fname + "0")
        affv[1,:,:,:] = emirt.io.znn_img_read(out_fname + "1")
        affv[2,:,:,:] = emirt.io.znn_img_read(out_fname + "2") 
        return affv
    elif not isaff and len(gznn_net_names)==1:
        # boundary map output
        return emirt.io.znn_img_read(out_fname + "1")
    else:
	raise ErrorName('unsupported parameters!')

#%% 
def znn_forward(z1,z2,y1,y2,x1,x2):
    """
    get data from big channel hdf5 file
    the coordinate range is in the affinity map
    """
    # if we already have this file, directly return
    if os.path.exists( gtmp+'affin_Z{}-{}_Y{}-{}_X{}-{}.h5'.format(z1,z2,y1,y2,x1,x2) ):
        return
    # clear and prepare local temporal folder
    if os.path.exists(gtmp):
	shutil.rmtree(gtmp)
    os.mkdir(gtmp)
    
    # read the cube
    f = h5py.File(gtmp+'chann_Z{}-{}_Y{}-{}_X{}-{}.h5'.format(z1,z2,y1,y2,x1,x2), 'r')
    cv = np.asarray(f['/main'])
    f.close()
    
    # run forward for this cube
    affv = znn_forward_cube(cv)
    # ensure the size is correct
    if affv.shape[0]!=z2-z1 or affv.shape[1]!=y2-y1 or affv.shape[2]!=x2-x1:
        raise NameError('the size of znn output is incorrect!')
    # save this cube
    f = h5py.File( gtmp+'affin_Z{}-{}_Y{}-{}_X{}-{}.h5'.format(z1,z2,y1,y2,x1,x2) )
    f['/main'] = affv
    f.close()

if __name__ == "__main__":
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
