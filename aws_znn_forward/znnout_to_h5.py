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

    -Network Output HDF5 File ("{output_filename}")
    -Channel Data HDF5 File ("channel_{output_filename}")

Nicholas Turner, June 2015
"""

from emirt import io
import h5py
import argparse
import numpy as np
from os import path
from vol_utils import crop, norm
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


def main(net_output_filenames, image_filename, output_filename):

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

    image_outname = 'channel_{}'.format(path.basename(output_filename))

    print "Writing network output file..."
    write_affinity_file(net_output, output_filename)
    print "Writing image file..."
    write_channel_file(cropped_image, image_outname)

if __name__ == '__main__':
    #%% convert znn output to hdf5 file
    fname = gznn_znnpath + "experiments/W59_C10_P3_D3/output/out92."
    gnet_out_fnames = (fname+"0", fname+"1", fname+"2")
    gchann_fname = gznn_znnpath + "dataset/fish/data/batch92.image"
    main(gnet_out_fnames, gchann_fname, gaffin_file)
