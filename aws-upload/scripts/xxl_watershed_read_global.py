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
	
   # rearrage the index
	# for idx, segi in enumerate(segm):
	# 	vol[ vol==segi ] = idx
	# 	chunk_dend[ chunk_dend==segi ] = idx
		
	return vol, chunk_dend, chunk_dendValues

def write_h5_with_dend(h5filename, vol, dend, dendValues):
	import h5py
	f = h5py.File( h5filename, "w" )
	f.create_dataset('/main', data = vol )
	f.create_dataset('/dend', data=dend, dtype='uint32')
	f.create_dataset('/dendValues', data=dendValues, dtype='single')
	f.close()
	
def write_h5_chann( h5filename, vol ):
	import h5py
	f = h5py.File( h5filename, "w" )
	f.create_dataset('/main', data = vol )
	f.close()

def get_chunk_size(chunkSizes,chunkNum, z,y,x):    
	# chunk sizes
	sze = chunkSizes[ z+y*3+ x*3*3 ]
	return sze

def get_volume_info( filename ):
	 # number of chunks in the xyz direction
	chunkNum = np.fromfile(filename+".metadata", dtype='uint32')[2:5][::-1]
	# chunk sizes
	chunksizes = np.fromfile(filename+".chunksizes", dtype='uint32')[::-1].reshape(-1,3)
	
	print chunksizes

	# the whole volume size
	chunksizes1 = chunksizes.reshape(chunkNum[0],chunkNum[1],chunkNum[2],3)
	s = np.zeros(3, dtype='uint32')
	s[0] = np.sum(chunksizes1[:,0,0, 0])
	s[1] = np.sum(chunksizes1[0,:,0, 1])
	s[2] = np.sum(chunksizes1[0,0,:, 2])
	# remove the overlap
	s -= (chunkNum-1)*2
 
	 # the chunk size
	width = np.min( chunksizes,axis=0 )
	return chunkNum, chunksizes, width, s

def write_cmd( fname ):
	cmdfname = '../omnify/' + fname + ".cmd"
	fcmd = open(cmdfname, 'w')
	fcmd.write('create:'+ fname+'.omni\n')
	fcmd.write('loadHDF5chann:' + fname + '.chann.h5\n')
	fcmd.write('setChanResolution:1,7,7,40\n')
	fcmd.write('loadHDF5seg:'+ fname +'.segm.h5\n')
	fcmd.write('setSegResolution:1,7,7,40\n')
	fcmd.write('mesh\n')
	fcmd.write('quit\n\n')
	fcmd.close()
	
def write_sh(shfname, fname, omnifybin):
	fsh = open( shfname, 'w' )
	fsh.write('#!/bin/bash\n')
	fsh.write(omnifybin + " --headless --cmdfile='" + fname + ".cmd'")
	fsh.close()
def write_runall_sh(blockNum):
	fsh = open('../omnify/runall.sh', 'w')
	fsh.write('#!/bin/bash\n')
	for idx in range(blockNum):
		fsh.write( 'sh chunk_' +str(idx+1) + '.sh\n' )
	fsh.close()

def show_chunk(chk, z):
    import sys
    sys.path.append("/usr/people/jingpeng/libs/")
    import neupy.show
    neupy.show.random_color_show( chk[z,:,:] )

# out-of-core processing, generate a bunch of h5 files
def xxl_watershed_read_global( filename, blocksize, overlap, omnifybin ):
    chunkNum, chunkSizes, width, s = get_volume_info( filename )

    # the temporal volume of whole dataset
    import h5py
    tmpfilename = '../watershed/tmp_seg.h5'
    try:
#        import os
        os.remove(tmpfilename)
    except OSError:
        pass
    ftmp = h5py.File( tmpfilename, "w" )
    seg = ftmp.create_dataset('/main', tuple(s), \
			 chunks=tuple(width), dtype='uint32' )
    
    # feed the temporal volume with chunks
    print "feed the temporal volume with chunks ..."
    zabs = 0
    for z_chunk in range(chunkNum[0]):
        yabs = 0        
        for y_chunk in range(chunkNum[1]):
            xabs = 0            
            for x_chunk in range(chunkNum[2]):
                sze = chunkSizes[z_chunk+y_chunk*chunkNum[0] + \
                        x_chunk * chunkNum[0] * chunkNum[1], :]    
                cfrom = np.array([zabs,yabs,xabs])+1
                cto = cfrom + sze -2
                print "size: {}".format(sze)
                print "C: {},{},{}".format(z_chunk,y_chunk, x_chunk)
                print "Cabs: {},{},{}".format(zabs,yabs,xabs)
                print "cfrom: {}".format(cfrom)
                print "cto: {}".format(cto)
                segfname = filename + '.chunks/' + str(x_chunk) + '/' + str(y_chunk) + '/' + str(z_chunk) + '/.seg'
                chk = np.reshape( np.fromfile(segfname, dtype='uint32' ), sze)

#                chk = chk.transpose((0,2,1))
                
                seg[ cfrom[0]:cto[0], cfrom[1]:cto[1], cfrom[2]:cto[2] ] = chk[ 1:-1, 1:-1, 1:-1 ]			   
                xabs +=  sze[2]-3
            yabs +=  sze[1]-3
        zabs +=  sze[0]-3
	# the dend and dend values
	dendValues = np.fromfile( filename + '.dend_values', dtype='single' )#[::-1]
	dend = np.fromfile( filename + '.dend_pairs', dtype = 'uint32' )#[::-1]
	dend = dend.reshape((len(dendValues), 2)).transpose()
	
	ftmp.close()  
	ftmp = h5py.File( tmpfilename, "r" )
	seg = ftmp['/main']
			 
	print "get the blocks ..."
	# get the blocks of seg

	channfilename = '../watershed/stack.chann.hdf5'
	fchann = h5py.File( channfilename, 'r')
	chann = fchann['/main']    
	
	blockid = 0
	for bz in range(0, s[0], blocksize[0]):
		for by in range(0, s[1], blocksize[1]):
			for bx in range(0, s[2], blocksize[2]):
				blockid += 1                
				bfrom = np.array([ bz, by, bx ])                
				bto = np.minimum(s, bfrom+blocksize+overlap)
				print "blockid: {}".format(blockid)
				print "bfrom: {}".format(bfrom)
				print "bto  : {}".format(bto)
				block = seg[bfrom[0]:bto[0], bfrom[1]:bto[1], bfrom[2]:bto[2] ]
				block, chunk_dend, chunk_dendValues = truncate_dend(block, dend, dendValues)
				# write the h5 file
				fname = "chunk_" + str(blockid) + \
						"_Z" + str(bfrom[0]) + '-' + str(bto[0]-1) + \
						"_Y" + str(bfrom[1]) + '-' + str(bto[1]-1) + \
						"_X" + str(bfrom[2]) + '-' + str(bto[2]-1)
				# write the segmentation h5 file
				h5fname = '../omnify/' + fname + ".segm.h5"
    
                     # note that here exist a transpose
				write_h5_with_dend( h5fname, block, chunk_dend, chunk_dendValues )
				
				# write channel data
				block_chann = chann[bfrom[0]:bto[0], bfrom[1]:bto[1], bfrom[2]:bto[2] ]
				write_h5_chann( '../omnify/'+fname+'.chann.h5', block_chann )
				
				# write omnify cmd file
				write_cmd( fname )
				# generate a corresponding sh file
				shfname =  '../omnify/' + "chunk_" + str(blockid) + ".sh"
				write_sh(shfname, fname, omnifybin)
	
	# write a general bash file
	write_runall_sh(blockid)
				
	# close and remove the temporal file
	ftmp.close()
	# close channel file
	fchann.close()
	
	
def evaluate_seg(h5filename, z):
	import h5py
	f = h5py.File( h5filename )
	vol = np.asarray( f['/main'] )
	f.close()
	import matplotlib.pylab as plt
	plt.matshow(vol[z,:,:])

if __name__ == "__main__":
	import os
	
	filename = '../watershed/data/input'
	# the path of omnify binary
	omnifybin = 'bash ../omnify/omnify.sh'
	# the block size and overlap size, z,y,x
	blocksize = np.array([2000, 2000, 452])
	overlap = np.array([2,2,2])
	
	# run function
	xxl_watershed_read_global( filename, blocksize, overlap, omnifybin )
	
	# evaluate result
#    h5filename = DirDst + "chunk_0_Z0-99_Y0-99_X0-99.h5"
#    evaluate_seg(h5filename, 5)
	print("--finished generating the h5 file --")