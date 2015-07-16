#!/usr/bin/env python
__doc__ = """
Quick Conversion of ZNN volume files to hdf5 file format

 This module transfers 3d channel data volumes, and 4d affinity graph
files (or any 4d output file), to hdf5 file format. The channel data
is cropped to the 3d shape of one of the affinity volumes before
conversion. Cropping takes evenly from both sides, in line with the
loss of resolution common with convolutional nets.

Inputs:

    -Network Output Filename
    -Channel Data Filename
    -Output Filename

Main Outputs:

    -Network Output HDF5 File ("{h5_aff_fname}")
    -Channel Data HDF5 File ("channel_{h5_aff_fname}")

Nicholas Turner, June 2015
"""

from emirt import io
import h5py
import argparse
import numpy as np
from os import path
from emirt.volume_util import crop, norm
from global_vars import *

def write_channel_file(data, filename, dtype='float32'):
    '''Placing the cropped channel data within an hdf5 file'''

    f = h5py.File(filename, 'w')
    dset = f.create_dataset('/main', tuple(data.shape), dtype=dtype)
    #Saving a NORMALIZED version of the data (0<=d<=1)
    dset[:,:,:] = norm(data.astype(dtype))
    f.close()

def write_affinity_file(data, filename, dtype='float32'):
    '''Placing the affinity graph within an hdf5 file dataset of 3d size
    specified by shape, and the number of volumes equal to the input data'''

    f = h5py.File(filename, 'w')
    dset = f.create_dataset('/main', tuple(data.shape), dtype=dtype)
    #Saving data
    dset[:, :,:,:] = data.astype(dtype)
    f.close()


def main(net_output_filenames, image_filename ):

    print "Importing data..."
    if len(net_output_filenames)==1 :
        net_output = io.znn_img_read(net_output_filenames[0])
    elif len(net_output_filenames)==3 :
        net_output0 = io.znn_img_read( net_output_filenames[0] )
        net_output = np.zeros((3,) + net_output0.shape, dtype = "float32")
        net_output[0,:,:,:] = net_output0
        net_output[1,:,:,:] = io.znn_img_read( net_output_filenames[1] )
        net_output[2,:,:,:] = io.znn_img_read( net_output_filenames[2] )
    else:
        raise("not correct net_output_filenames!")

    image = io.znn_img_read(image_filename)

    print "Cropping channel data..."
    #cropping the channel data to the 3d shape of the affinity graph
    cropped_image = crop(image, net_output.shape[-3:])

    print "Writing network output file..."
    write_affinity_file(net_output, gaffin_file)
    print "Writing image file..."
    write_channel_file(cropped_image, gchann_file)

if __name__ == '__main__':
    #%% convert znn output to hdf5 file
    fname = gznn_znnpath + "/experiments/VeryDeep2HR_w65x9/output/out92."
    gnet_out_fnames = (fname+"0", fname+"1", fname+"2")
    main(gnet_out_fnames, gznn_chann_fname )
