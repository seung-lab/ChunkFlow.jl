#!/usr/bin/env python 

__doc__ = """

merge_out_vols.py ${x_affinity} ${y_affinity} ${z_affinity}

     Some older versions of ZNN save 3 separate data files for the 
     affinity graph output (one for x, y, and z). This script merges
     those into one volume, generally in preparation for convert_to_hdf5
     and omnification.

     The resulting output volume is saved under the prefix of the first

Nicholas Turner, 2015
"""

from sys import argv
import numpy as np 
import io

print "Loading Data..."
vols = [io.znn_img_read(filename) for filename in argv[1:]]

final_shape = np.concatenate(([len(vols)], vols[0].shape))

merged = np.empty((final_shape))

print "Arranging Data..."
for t in range(merged.shape[0]):
	merged[t,:,:,:] = vols[t]

outname = argv[1].split('.')[0]

print "Saving Data..."
io.znn_img_save(merged, outname)
