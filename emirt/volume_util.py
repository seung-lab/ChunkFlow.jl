# -*- coding: utf-8 -*-
"""
Created on Wed Mar  4 16:40:08 2015

@author: jingpeng
"""
import numpy as np
#%% add boundary between connected regions
def add_boundary_im(im):
    Ni, Nj = im.shape
    im2 = np.copy(im)
    for i in range(1,Ni-1):
        for j in range(1,Nj-1):
            mat = im[i-1:i+2, j-1:j+2]
            nzi,nzj = mat.nonzero()
            if len(np.unique( mat[nzi,nzj] ))>1 :
                im2[i,j]=0
    return im2

def add_boundary_2D(vol):
    Nz,Ny,Nx = vol.shape 
    for z in range(Nz): 
        vol[z,:,:] = add_boundary_im(vol[z,:,:])
    return vol
    
def add_boundary_3D(vol, neighbor = 6):
    Nz,Ny,Nx = vol.shape 
    vol2 = np.copy(vol)
    for z in range(1,Nz-1):
        for y in range(1,Ny-1):
            for x in range(1,Nx-1):
                mat = vol[z-1:z+2,y-1:y+2,x-1:x+2]
                if neighbor == 6:
                     neighbor6 = [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0,1,1,1,0, 1, 0, 0, 0,0, 0, 1, 0, 0, 0, 0]
                     neighbor6 = np.asarray(neighbor6).reshape(3,3,3)
                     mat = mat * neighbor6
                nzz,nzy,nzx = mat.nonzero()
                if mat[1,1,1]!=0 and len(np.unique( mat[nzz,nzy,nzx] )) > 1:
                    vol2[z,y,x] = 0
    # the first and last image
    vol2[0,:,:] = add_boundary_im(vol[0,:,:])
    vol2[Nz-1,:,:] = add_boundary_im(vol[Nz-1,:,:])
    return vol2


def crop(vol, target_shape):
	'''Crops the input volume to fit to the target shape'''
	if any([vol.shape[i] < target_shape[i] for i in range(len(target_shape))]	):
		raise ValueError('volume already smaller that target volume!')

	dim_diffs = (np.array(vol.shape) - np.array(target_shape)) / 2

	#Cropping dimensions one at a time
	cropped = vol
	if dim_diffs[0] > 0: #unlikely

		cropped = vol[
			dim_diffs[0]:-(dim_diffs[0]),
			:,
			:
		]

	if dim_diffs[1] > 0:
		cropped = cropped[
			:,
			dim_diffs[1]:-(dim_diffs[1]),
			:
			]

	if dim_diffs[2] > 0:
		cropped = cropped[
			:,
			:,
			dim_diffs[2]:-(dim_diffs[2])
		]

	return cropped

def norm(vol):
	'''Normalizes the input volume to have values between 0 and 1
	(achieved by factor normalization to the max)'''

	vol = vol - np.min(vol.astype('float32'))
	vol = vol / np.max(vol)

	return vol
