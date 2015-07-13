#!/usr/bin/env python
__doc__ = """
chopping the big volume to small chunks for watershed

Jingpeng Wu <jingpeng.wu@gmail.com>, 2015
"""
import numpy as np
import os
import h5py
import time
from global_vars import *

def watershed_chop():
    #%% prepare the folders
    if os.path.exists(gtemp_file):
        os.system('rm -rf ' + gtemp_file + 'input*')
    os.makedirs(gtemp_file + 'input.chunks/')

    #%% read hdf5
    f = h5py.File(gaffin_file, 'r')
    affin = f['/main']

    s = np.array(affin.shape, dtype='uint32')[1:]
    s.tofile(gtemp_file + 'input.total_size')

    # width can not be bigger than total volume size
    global width
    width = np.minimum(gws_width, s)
    width.tofile(gtemp_file + 'input.width')

    fa = open(gtemp_file + 'input.affinity.data', mode='w+')

    chunkSizes = []
    chunkid = 0
    for cidx, x in enumerate(range(0, s[2], gws_width[2]) ):
        for cidy, y in enumerate(range(0, s[1], gws_width[1])):
            for cidz, z in enumerate( range(0, s[0], gws_width[0]) ):
               chunkid += 1
               print "chunk ID: {}".format(chunkid)
               start_tmp = time.clock()
               cfrom = np.maximum( np.array([z,y,x])-1, np.array([0,0,0]))
               cto = np.minimum(np.array([z,y,x]) + width + 1, s)
               size = cto - cfrom
               chunkSizes.append( size[::-1] )

               # the chunk part
               part = affin[:,cfrom[0]:cto[0], cfrom[1]:cto[1], cfrom[2]:cto[2]]
               part.tofile(fa)

               # create some folders for watershed
               os.makedirs(gtemp_file + 'input.chunks/{0}/{1}/{2}'.format(cidx,cidy,cidz))
               print "python clock time {0:.1f}s".format( time.clock()-start_tmp )
    # close the files
    f.close()
    fa.close()

    # metadata and size
    metadata = np.array([32, 32, cidx+1, cidy+1, cidz+1]).astype('uint32')
    metadata.tofile(gtemp_file + 'input.metadata')

    chunkSizes = np.array( chunkSizes, dtype='uint32' )
    chunkSizes.tofile(gtemp_file + 'input.chunksizes')


#%%
if __name__ == "__main__":
    watershed_chop()
    # run watershed
    #print 'run watershed '
    os.system(gws_bin_file + " --filename=" + gtemp_file + "input "\
                + "--high={} --low={} --dust={} --dust_low={} --threads={}".format(gws_high, gws_low, gws_dust, gws_dust_low, gws_threads_num))
