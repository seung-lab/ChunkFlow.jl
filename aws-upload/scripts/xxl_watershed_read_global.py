# -*- coding: utf-8 -*-
"""
Created on Fri Feb 27 13:39:22 2015

@author: jingpeng
"""
import numpy as np

# out-of-core processing, this is the desired function, but maybe slow without chunking
def xxl_watershed_read_global( filename, s, width, h5filename ):
    import h5py
    f = h5py.File( h5filename, "w" )
    chunksize = np.array([width, width, width])
    seg = f.create_dataset('/main', tuple(s), chunks=tuple(chunksize), dtype='uint32' )
    # note that the chunk was transposed implicitly by reversing s order
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
                print( "prepared chunk {}:{}:{} fname: {}, size: {} \n".format(x,y,z,fname,cto-cfrom+1) )
                zind += 1
            yind += 1
        xind += 1
        
    dend_values = np.fromfile( filename + '.dend_values', dtype='single' )
    dend = np.fromfile( filename + '.dend_pairs', dtype = 'uint32' )
    dend = dend.reshape((2, len(dend_values)))
    
    # write the h5 file
    f.create_dataset('/dend', data=dend, dtype='uint32')
    f.create_dataset('/dendValues', data=dend_values, dtype='single')
    f.close()

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
                
                print( "prepared chunk {}:{}:{} fname: {}, size: {} \n".format(x,y,z,fname,cto-cfrom+1)  )
                
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
    for segi in segm:
        ri, ci = np.where(segi==dend)
        c = np.concatenate([c,ci])
    c = c.astype('int')
    chunk_dend = dend[:,c]
    chunk_dendValues = dendValues[c]    
    
    # rearrage the index
    for idx, segi in enumerate(segm):
        vol[ vol==segi ] = idx
        dend[ dend==segi ] = idx
    
    return vol, chunk_dend, chunk_dendValues

def write_h5(h5filename, vol, dend, dendValues):
    import h5py
    f = h5py.File( h5filename, "w" )
    f.create_dataset('/main', data = vol )
    f.create_dataset('/dend', data=dend, dtype='uint32')
    f.create_dataset('/dendValues', data=dendValues, dtype='single')
    f.close()

# out-of-core processing, generate a bunch of h5 files
def xxl_watershed_read_global_V2( filename, s, width, Dir ):
#    # make directory
#    import os
#    os.mkdir(Dir)    
    
    # dend    
    dendValues = np.fromfile( filename + '.dend_values', dtype='single' )
    dend = np.fromfile( filename + '.dend_pairs', dtype = 'uint32' )
    dend = dend.reshape((2, len(dendValues)))
    
    # note that the chunk was transposed implicitly by reversing s order
    chunkid = 0
    xind = 0
    for x in range(0, s[2], width):
        yind = 0
        for y in range(0, s[1], width):
            zind = 0
            for z in range(0, s[0], width):
                chunkid += 1
                cto = np.minimum( np.array([z,y,x])+width, s-1 );
                cfrom = np.maximum( np.array([0,0,0]), np.array([z,y,x])-1 )
                fname = filename + '.chunks/' + str(xind) + '/' + str(yind) + '/' + str(zind) + '/.seg'
                sze = cto - cfrom + 1
                chk = np.reshape( np.fromfile(fname, count = np.prod(sze), dtype='uint32' ), sze)
                
                # generate a h5 file
                vol = chk[ 1:-1, 1:-1, 1:-1 ]
                chunk_vol, chunk_dend, chunk_dendValues = truncate_dend( vol, dend, dendValues )
                fname = Dir + "chunk_" + str(chunkid) + \
                        "_X" + str(cfrom[0]+1) + "-" + str(cto[0]-1) + \
                        "_Y" + str(cfrom[1]+1) + "-" + str(cto[1]-1) + \
                        "_Z" + str(cfrom[2]+1) + "-" + str(cto[2]-1) + ".h5"
                write_h5(fname, chunk_vol, chunk_dend, chunk_dendValues)

                print( "prepared chunk {}:{}:{} fname: {}, size: {} \n".format(x,y,z,fname,cto-cfrom+1) )
                zind += 1
            yind += 1
        xind += 1

def evaluate_seg(h5filename, z):
    import h5py
    f = h5py.File( h5filename )
    vol = np.asarray( f['/main'] )
    f.close()
    import matplotlib.pylab as plt
    plt.matshow(vol[z,:,:])
    return

if __name__ == "__main__":
    filename = '/usr/people/jingpeng/seungmount/research/Jingpeng/01_workspace/03_watershed/WS_scripts/temp/wstemp'
    # volume size
    s = np.array([126, 400, 400])
    # the width determines the size of each chunk
    width = np.min(s)
    h5file = '/usr/people/jingpeng/seungmount/research/Jingpeng/01_workspace/04_omni_project/out1.1/'
    
#    # remove file
#    import os
#    if os.path.exists(h5file):
#        os.remove( h5file )    
    
    xxl_watershed_read_global_V2( filename, s, width, h5file )
    
    # evaluate the volume
    #evaluate_seg(h5file, 1)
    print("--finished generating the h5 file --")
    
    