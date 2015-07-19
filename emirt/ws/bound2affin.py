# -*- coding: utf-8 -*-
"""
Created on Fri Jan 30 15:40:09 2015

transform boundary map to affinity graph
prepare affinity graph for watershed

@author: jingpeng
"""
import numpy as np
import neupy

#%% parameters
Dir = './01_data/'

fname = 'out1.1'

#%% read volume
prob = np.fromfile(Dir+fname, dtype='double')
Nx,Ny,Nz = np.fromfile(Dir+fname+'.size', dtype='uint32')
prob = prob.reshape((Nz,Ny,Nx))

def cubic(t):
    '''
    compute the cubic
    '''
    return 4*(t-0.5)**3+0.5

   
#%% generate affinity graph by directly combine the probability volume
affin = np.zeros((3,Nz,Ny,Nx), dtype='double')

for k in range(Nz):
    neupy.show.progress(k+1, Nz)
    for j in range(Ny):
        for i in range(Nx):
            o=prob[k,j,i]            
            if i==Nx-1:
                x=o
            else:
                x=prob[k,j,i+1]
            if j==Ny-1:
                y=o
            else:
                y=prob[k,j+1,i]
            if k==Nz-1:
                z=o
            else:
                z=prob[k+1,j,i]
            
            affin[0,k,j,i] =np.sqrt(cubic(x)*cubic(o))
            affin[1,k,j,i] =np.sqrt(cubic(y)*cubic(o))
            affin[2,k,j,i] =np.sqrt(cubic(z)*cubic(o))
            
#affin2 = affin.transpose((3,2,1,0))
#%% visualization


#%% write the affinity graph
affin.tofile( Dir + fname + '.affin.raw')

#%% 
