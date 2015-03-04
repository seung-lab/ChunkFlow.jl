# -*- coding: utf-8 -*-
"""
Created on Fri Feb 27 13:39:22 2015

@author: jingpeng
"""
import numpy as np

# the first version needs to load all the data into memory
def xxl_watershed_read_global_V1( filename, s, width, h5filename ):
    seg = np.zeros( s, dtype='uint32' )
    xind = 0
    for x in range(0, s[2], width):
        yind = 0
        for y in range(0, s[1], width):
            zind = 0
            for z in range(0, s[0], width):
                cto = np.minimum( np.array([z,y,x])+width, s-1 );
                cfrom = np.maximum( np.array([0,0,0]), np.array([z,y,x])-1 )
                fname = filename + '.chunks/' + str(xind) + '/' + str(yind) + '/' + str(zind) + '/.seg'
                sze = cto - cfrom + 1
                chk = np.reshape( np.fromfile(fname, count = np.prod(sze), dtype='uint32' ), sze)
                seg[ cfrom[0]+1:cto[0], cfrom[1]+1:cto[1], cfrom[2]+1:cto[2] ] = chk[ 1:-1, 1:-1, 1:-1 ]
                print( "prepared chunk {}:{}:{}, size: {} \n".format(x,y,z, sze) )
                zind += 1
            yind += 1
        xind += 1
    dend_values = np.fromfile( filename + '.dend_values', dtype='single' )
    dend = np.fromfile( filename + '.dend_pairs', dtype = 'uint32' )
    dend = dend.reshape((2, len(dend_values)))
    # write the h5 file
    import h5py
    f = h5py.File( h5filename )
    f.create_dataset('/main',data=seg)
    f.create_dataset('/dend', data=dend, dtype='uint32')
    f.create_dataset('/dendValues', data=dend_values, dtype='single')
    f.close()


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
def xxl_watershed_read_global( filename, Dir, step ):    
    # dend    
    dendValues = np.fromfile( filename + '.dend_values', dtype='single' )
    dend = np.fromfile( filename + '.dend_pairs', dtype = 'uint32' )
    dend = dend.reshape((2, len(dendValues)))
    
    
    # number of chunks in the xyz direction
    chunkNum = np.fromfile(filename+".metadata", dtype='uint32')[2:5][::-1]
    # chunk sizes
    chunksizes1 = np.fromfile(filename+".chunksizes", dtype='uint32').reshape(-1,3)
    chunksizes2 = chunksizes1[:,::-1]
    chunksizes = chunksizes2.reshape( tuple(np.hstack((chunkNum, 3))) ).transpose(0,2,1,3)
    
    width = np.min( chunksizes[0,0,0,:] )
    
    chunkid = 0
    for zind in range(0, chunkNum[0], step[0]):
        for yind in range(0, chunkNum[1], step[1]):
            for xind in range(0, chunkNum[2], step[2]):
                chunkid += 1
                # create the buffer
                buffersize = np.array([0,0,0])
                # the start coordinate of 
                for sz in range(step[0]):
                    buffersize[0] += chunksizes[zind + sz,0,0, 0]
                for sy in range(step[1]):
                    buffersize[1] += chunksizes[0,yind + sy,0, 1]
                for sx in range(step[2]):                           
                    buffersize[2] += chunksizes[0,0,xind + sx, 2]
                # create the buffer volume
                buffervol = np.zeros(buffersize, dtype='uint32')
                # the buffer coordinate
                bfrom = np.maximum( np.array([0,0,0]), np.array([ zind*width, yind*width, xind*width ])-1 )
                
                # the start coordinate of 
                for sz in range(step[0]):
                    chunkidz = zind + sz;
                    for sy in range(step[1]):
                        chunkidy = yind + sy;
                        for sx in range(step[2]):
                            chunkidx = xind + sx;
                            # chunk size
                            sze = chunksizes[chunkidz, chunkidy, chunkidx, :]
                            fname = filename + '.chunks/' + str(chunkidx) + '/' + str(chunkidy) \
                                    + '/' + str(chunkidz) + '/.seg'
                            chk = np.reshape( np.fromfile(fname, count = np.prod(sze), dtype='uint32' ), sze)
                            
                            # the from and to
                            cfrom = np.maximum( np.array([0,0,0]), \
                                    np.array([bfrom[0]+sz*width, bfrom[1]+sy*width, bfrom[2]+sx*width])-1 )
                            # chunk coordinate in buffer
                            cbfrom = cfrom - bfrom
                            cbto = cbfrom+sze-1
                            
                            buffervol[cbfrom[0]+1:cbto[0], cbfrom[1]+1:cbto[1], \
                                      cbfrom[2]+1:cbto[2]] = chk[1:-1,1:-1,1:-1]
                                      
                # remove the redundant dends, which contains dend outsize this buffer volume
                buffervol, chunk_dend, chunk_dendValues = truncate_dend(buffervol, dend, dendValues)
                # write the buffer to h5 file                
                print "write the h5 file ..."
                fname = Dir + "chunk_" + str(chunkid) + "_Z" + str(bfrom[0]) + \
                        "_Y" + str(bfrom[1]) + "_X" + str(bfrom[2]) + ".h5"
                write_h5(fname, buffervol, chunk_dend, chunk_dendValues)
         

def evaluate_seg(h5filename, z):
    import h5py
    f = h5py.File( h5filename )
    vol = np.asarray( f['/main'] )
    f.close()
    import matplotlib.pylab as plt
    plt.matshow(vol[z,:,:])

if __name__ == "__main__":
    filename = '/usr/people/jingpeng/seungmount/research/Jingpeng/01_workspace/03_watershed/WS_scripts/temp/wstemp'
    # the directory for saving the h5 files
    h5dir = '/usr/people/jingpeng/seungmount/research/Jingpeng/01_workspace/04_omni_project/out1.1/'
    # the chunk number to be merged, z,y,x
    mergeNum = np.array([1, 2, 2])
    xxl_watershed_read_global( filename, h5dir, mergeNum )
    
#    xxl_watershed_read_global_V1( filename, np.array([126,400,400]), 126, h5dir+"chunk_1_Z0_Y0_X0.h5" )
    
    # evaluate result
    h5filename = h5dir + "chunk_1_Z0_Y0_X0.h5"
    evaluate_seg(h5filename, 5)
    print("--finished generating the h5 file --")
    
    