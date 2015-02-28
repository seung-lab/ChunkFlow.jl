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

    return seg, dend, dend_values
    
# out-of-core processing
def xxl_watershed_read_global( filename, s, width, h5filename ):
    
    import h5py
    f = h5py.File( h5filename, "w" )
    chunksize = np.array([width, width, width])
    seg = f.create_dataset('/main', tuple(s), chunks=tuple( chunksize ), dtype='uint32' )
    
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
                
                chk = np.reshape( np.fromfile(fname, count = np.prod(sze), dtype='uint32' ), sze )
                seg[ cfrom[0]+1:cto[0], cfrom[1]+1:cto[1], cfrom[2]+1:cto[2] ] = chk[ 1:-1, 1:-1, 1:-1 ]
                
                print( "prepared chunk {}:{}:{} fname: {}, size: {} \n".format(x,y,z,fname,cto-cfrom+1)  )
                
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

    return seg, dend, dend_values

if __name__ == "__main__":
    filename = '/usr/people/jingpeng/seungmount/research/Jingpeng/01_workspace/03_watershed/WS_scripts/temp/wstemp'
    s = np.array([126, 400, 400])
    width = np.min(s)
    h5filename = '/usr/people/jingpeng/seungmount/research/Jingpeng/01_workspace/04_omni_project/out1.1.h5'
    seg, dend, dend_values = xxl_watershed_read_global( filename, s, width, h5filename )
    
    