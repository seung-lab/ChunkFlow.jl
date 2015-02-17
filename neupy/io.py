# -*- coding: utf-8 -*-
"""
Created on Wed Jan 28 14:27:31 2015

@author: jingpeng
"""

#import sys
#sys.path.append('./tifffile')

import numpy as np
import h5py
#import tifffile

#%% read hdf5 volume
def imread( fname ):
    if '.hdf5' in fname or '.h5' in fname:
        fname = fname.replace(".hdf5", "")
        f = h5py.File( fname )
        v = np.asarray( f['/main'] )
        f.close()
        print 'finished reading image stack :)'
        return v
    elif '.tif' in fname:
#        import skimage.io
#        return skimage.io.imread( fname, plugin='tifffile' )  
        import tifffile
        return tifffile.imread(fname)
    else:
        print 'file name error, only suport tif and hdf5 now!!!'
        

def imsave( vol, fname, order='C' ):
#    if order=='F':
#        vol=vol.transpose((2,1,0))
    
    if '.hdf5' in fname or '.h5' in fname:
        f = h5py.File( fname )
        f.create_dataset('/main', data=vol)
        f.close()
        print 'hdf5 file was written :)'
    elif '.tif' in fname:
        import skimage.io
        skimage.io.imsave(fname, vol, plugin='tifffile')
    else:
        print 'file name error! only support tif and hdf5 now!!!'
        
def save_variable( var, vname ):
    import pickle
    f = open(vname, 'w')
    pickle.dump(var, f)
    f.close()
    
def load_variable( vname ):
    import pickle
    f = open( vname, 'rb' )
    var = pickle.load(f)
    f.close()
    return var

def write_for_znn(Dir, vol, cid):
    '''transform volume to znn format'''
    # make directory
    import neupy.os    
    neupy.os.mkdir_p(Dir )
    neupy.os.mkdir_p(Dir + 'data')
    neupy.os.mkdir_p(Dir + 'spec')
    vol.tofile(Dir + 'data/' + 'batch'+str(cid)+'.image')
    sz = np.asarray(vol.shape)
    sz.tofile(Dir + 'data/' + 'batch'+str(cid)+'.size')
    
    # printf the batch.spec
    f = open(Dir + 'spec/' + 'batch'+str(cid)+'.spec', 'w')
    f.write('[INPUT1]\n')
    f.write('path=./dataset/piriform/data/batch'+str(cid)+'\n')
    f.write('ext=image\n')
    f.write('size='+str(sz[2])+','+str(sz[1])+','+str(sz[0])+'\n')
    f.write('pptype=standard2D\n\n')
    