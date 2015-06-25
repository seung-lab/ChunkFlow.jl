# -*- coding: utf-8 -*-
"""
Created on Fri Feb 27 13:39:22 2015

@author: jingpeng
"""
import numpy as np
import os
from global_vars import *

def get_volume_info():
    # number of chunks in the xyz direction
    chunkNum = np.fromfile(gtemp_file + 'input.metadata', dtype='uint32')[2:5][::-1]
    # chunk sizes
    chunksizes = np.fromfile(gtemp_file + 'input.chunksizes', dtype='uint32').reshape(-1,3)[:,::-1]
    s = np.fromfile( gtemp_file + 'input.total_size', dtype='uint32' )
    print "volume size: "+ str(s)
#    width = np.repeat(s.min(),3)
    width = np.fromfile( gtemp_file + 'input.width', dtype='uint32' )
    width = np.minimum( gwidth, s )

    return chunkNum, chunksizes, width, s

# out-of-core processing, generate a bunch of h5 files
def watershed_merge( ):
    chunkNum, chunkSizes, width, s = get_volume_info()

    # the temporal volume of whole dataset
    import h5py

    try:
        os.remove( gws_merge_h5 )
    except OSError:
        pass
    ftmp = h5py.File( gws_merge_h5, "w" )
    if np.all(gblocksize >= s):
        # experiments shows that we could not use chunk and compression here!!!
        seg = ftmp.create_dataset('/main', tuple(s), dtype='uint32')
    else:
        seg = ftmp.create_dataset('/main', tuple(s), dtype='uint32' )

    # feed the temporal volume with chunks
    print "feed the temporal volume with chunks ..."
    xind = 0
    for x in xrange(0, s[2], width[2]):
        yind = 0
        for y in xrange(0, s[1], width[1]):
            zind = 0
            for z in xrange(0, s[0], width[0]):
                cfrom = np.maximum( np.array([0,0,0]), np.array([z,y,x])-1 )
                cto = np.minimum( s, np.array([z,y,x])+width+1 )
                sze = cto - cfrom
                print "size: {}, from: {}, to:{}".format(sze, cfrom, cto)
                segfname = gtemp_file + 'input' + '.chunks/' + str(xind) + '/' + str(yind) + '/' + str(zind) + '/.seg'
                chk = np.reshape( np.fromfile(segfname, dtype='uint32' ), sze)
                seg[ cfrom[0]+1:cto[0]-1, cfrom[1]+1:cto[1]-1, cfrom[2]+1:cto[2]-1 ] = chk[ 1:-1, 1:-1, 1:-1 ]

                zind += 1
            yind += 1
        xind += 1
    # unique seg ID, TO-DO


    # the dend and dend values
    dendValues = np.fromfile( gtemp_file + 'input.dend_values', dtype='single' )
    dend = np.fromfile( gtemp_file + 'input.dend_pairs', dtype = 'uint32' )
    dend = dend.reshape((len(dendValues), 2)).transpose()
    ftmp.create_dataset('/dend', data=dend, dtype='uint32')
    ftmp.create_dataset('/dendValues', data=dendValues, dtype='single')
    ftmp.close()


if __name__ == "__main__":
    # run function
    watershed_merge( )

    print("--finished generating the h5 file --")
