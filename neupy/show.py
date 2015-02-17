# -*- coding: utf-8 -*-
"""
Created on Wed Jan 28 14:28:47 2015

@author: jingpeng
"""
import numpy as np
#%% see 3D consensus
def show_3d_slices(vol):
    # transform to random color
    
    # transpose for correct show
    vol = vol.transpose()
    
    # show the image stack
    import pyqtgraph as pg
#    cm = np.random.rand(np.max(vol))
#    pg.colormap(cm)
    imv = pg.ImageView()
    imv.show()
    imv.setImage(vol)
    
# 3D volume rendering using mayavi
def mayavi_3d_rendering(vol):
    vol = vol.transpose()
    from mayavi import mlab
#    mlab.pipeline.volume(mlab.pipeline.scalar_field(vol))
    mlab.pipeline.image_plane_widget(mlab.pipeline.scalar_field(vol),
                                plane_orientation='z_axes',
                                slice_index=10,
                                )

def mat_show(mat, xlabel=''):
    import matplotlib.pylab as plt   
    fig = plt.figure()
    ax1 = fig.add_subplot(111)
    ax1.matshow(mat, cmap=plt.cm.gray_r)    
    # add numbers
    Nx, Ny = mat.shape()
    x,y = np.meshgrid(range(Nx), range(Ny))
    for i,j in zip(x.ravel(),y.ravel()):
        s = str( np.round(mat[i,j], decimals=2) )
        if mat[i,j]<np.mean(mat):
            ax1.annotate(s, xy=(i,j), ha='center', va='center')
        else:
            ax1.annotate(s, xy=(i,j), ha='center', va='center', color='white')
    ax1.set_xlabel(xlabel)
    plt.show()        

def imshow(im):
    import matplotlib.pylab as plt
    plt.imshow(im)
    
# show the labeled image with random color
def random_color_show( im, mode='im' ):
    import matplotlib.pylab as plt
    import matplotlib.colors as mcolor
    # make a random color map, but the background should be black
    cmap_array = np.random.rand ( im.max(),3)
    cmap_array[0] = [0,0,0]   
    cmap=mcolor.ListedColormap( cmap_array )
    if mode=='im':
        plt.imshow(im, cmap= cmap )
    elif mode=='mat':
        # approximate the matshow for compatability of subplot
        nr, nc = im.shape
        extent = [-0.5, nc-0.5, nr-0.5, -0.5]
        plt.imshow(im, extent=extent, origin='upper',interpolation='nearest', cmap=cmap) 
#        plt.matshow(im, cmap=mcolor.ListedColormap( cmap_array ) )
    else:
        print 'unknown mode'

def progress(count, total, suffix=''):
    import sys
    bar_len = 60
    filled_len = int(round(bar_len * count / float(total)))
    percents = round(100.0 * count / float(total), 1)
    bar = '=' * filled_len + '-' * (bar_len - filled_len)
    sys.stdout.write('[%s] %s%s ...%s\r' % (bar, percents, '%', suffix))