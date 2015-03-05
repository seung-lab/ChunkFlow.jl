# -*- coding: utf-8 -*-
"""
Created on Fri Feb 27 13:39:22 2015

@author: jingpeng
"""
import numpy as np

def truncate_dend(vol, dend, dendValues):
    segm = np.unique( vol )
    
    # truncate the dend
    c = []
    for di in range( len(dendValues) ):
        if dend[0,di] in segm and dend[1,di] in segm:
            c.append(di)
    chunk_dend = dend[:,c]
    chunk_dendValues = dendValues[c]    
    
#    # rearrage the index
#    for idx, segi in enumerate(segm):
#        print idx
#        vol[ vol==segi ] = idx
#        chunk_dend[ chunk_dend==segi ] = idx
    
    return vol, chunk_dend, chunk_dendValues

def write_h5(h5filename, vol, dend, dendValues):
    import h5py
    f = h5py.File( h5filename, "w" )
    f.create_dataset('/main', data = vol )
    f.create_dataset('/dend', data=dend, dtype='uint32')
    f.create_dataset('/dendValues', data=dendValues, dtype='single')
    f.close()

# out-of-core processing, generate a bunch of h5 files
def xxl_watershed_read_global( filename, Dir, blocksize, overlap ):       
    # number of chunks in the xyz direction
    chunkNum = np.fromfile(filename+".metadata", dtype='uint32')[2:5][::-1]
    # chunk sizes
    chunksizes1 = np.fromfile(filename+".chunksizes", dtype='uint32').reshape(-1,3)
    chunksizes2 = chunksizes1[:,::-1]
    chunksizes = chunksizes2.reshape( tuple(np.hstack((chunkNum, 3))) ).transpose(0,2,1,3)
    # the chunk size
    width = np.min( chunksizes[0,0,0,:] )
    
    # the whole volume size
    s = np.zeros(3, dtype='uint32')
    for sz in range(chunkNum[0]):
        s[0] += chunksizes[sz,0,0, 0]
    for sy in range(chunkNum[1]):
        s[1] += chunksizes[0,sy,0, 1]
    for sx in range(chunkNum[2]):                           
        s[2] += chunksizes[0,0,sx, 2]
    # remove the overlap
    s -= (chunkNum-1)*2
    
    # the temporal volume of whole dataset
    import h5py
    tmpfilename = Dir+'tmp_seg.h5'
    ftmp = h5py.File( tmpfilename, "w" )
    chunksize = np.array([width, width, width])
    seg = ftmp.create_dataset('/main', tuple(s), chunks=tuple(chunksize), dtype='uint32' )
    
    # feed the temporal volume with chunks
    for xind, x in enumerate(range(0, s[2], width)):
        for yind, y in enumerate( range(0, s[1], width) ):
            for zind, z in enumerate( range(0, s[0], width) ):
                cto = np.minimum( np.array([z,y,x])+width, s-1 );
                cfrom = np.maximum( np.array([0,0,0]), np.array([z,y,x])-1 )                
                sze = cto - cfrom + 1
                fname = filename + '.chunks/' + str(xind) + '/' + str(yind) + '/' + str(zind) + '/.seg'
                chk = np.reshape( np.fromfile(fname, count = np.prod(sze), dtype='uint32' ), sze)
                seg[ cfrom[0]+1:cto[0], cfrom[1]+1:cto[1], cfrom[2]+1:cto[2] ] = chk[ 1:-1, 1:-1, 1:-1 ]
    
    # the dend and dend values
    dendValues = np.fromfile( filename + '.dend_values', dtype='single' )
    dend = np.fromfile( filename + '.dend_pairs', dtype = 'uint32' )
    dend = dend.reshape((2, len(dendValues)))    
    
    # get the blocks of seg
    blockid = 0
    for bz in range(0, s[0], blocksize[0]):
        for by in range(0, s[1], blocksize[1]):
            for bx in range(0, s[2], blocksize[2]):
                blockid += 1                
                bfrom = np.array([ bz, by, bx ])                
                bto = np.minimum(s, bfrom+blocksize+overlap)
                print "bfrom: {}".format(bfrom)
                print "bto  : {}".format(bto)
                block = seg[bfrom[0]:bto[0], bfrom[1]:bto[1], bfrom[2]:bto[2] ]
                block, chunk_dend, chunk_dendValues = truncate_dend(block, dend, dendValues)
                # write the h5 file
                fname = Dir + "chunk_" + str(blockid) + \
                        "_Z" + str(bfrom[0]) + '-' + str(bto[0]-1) + \
                        "_Y" + str(bfrom[1]) + '-' + str(bto[1]-1) + \
                        "_X" + str(bfrom[2]) + '-' + str(bto[2]-1) + ".h5"
                write_h5(fname, block, chunk_dend, chunk_dendValues)
    # close and remove the temporal file
    ftmp.close()
    import os
    os.remove(tmpfilename)
    
    
def evaluate_seg(h5filename, z):
    import h5py
    f = h5py.File( h5filename )
    vol = np.asarray( f['/main'] )
    f.close()
    import matplotlib.pylab as plt
    plt.matshow(vol[z,:,:])

if __name__ == "__main__":
    filename = '/usr/people/jingpeng/seungmount/research/Jingpeng/01_workspace/03_watershed/WS_scripts/temp/wstemp'
    # the destination directory 
    DirDst = '/usr/people/jingpeng/seungmount/research/Jingpeng/01_workspace/04_omni_project/out1.1/'
    # the block size and overlap size, z,y,x
    blocksize = np.array([200, 200, 200])
    overlap = np.array([2,2,2])
    # run function
    xxl_watershed_read_global( filename, DirDst, blocksize, overlap )
    
    # evaluate result
#    h5filename = DirDst + "chunk_0_Z0-99_Y0-99_X0-99.h5"
#    evaluate_seg(h5filename, 5)
    print("--finished generating the h5 file --")
    
    