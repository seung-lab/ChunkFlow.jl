# -*- coding: utf-8 -*-
"""
Created on Wed Mar 25 12:19:44 2015

relabel the segmentation by connectivity analysis

@author: jingpeng
"""
import numpy as np
import h5py
import scipy.sparse
from global_vars import *

#%% depth first search
def dfs(seg, seg2, mask, relid, label, s, z,y,x):
    seeds = []
    seeds.append((z,y,x))
    while seeds:
        z,y,x = seeds.pop()
        seg2[z,y,x] = relid
        mask[z,y,x] = True

        if z+1<s[0] and seg[z+1,y,x] == label and not mask[z+1,y,x] :
            seeds.append((z+1,y,x))
        if z-1>=0    and seg[z-1,y,x] == label and not mask[z-1,y,x] :
            seeds.append((z-1,y,x))
        if y+1<s[1] and seg[z,y+1,x] == label and not mask[z,y+1,x] :
            seeds.append((z,y+1,x))
        if y-1>=0    and seg[z,y-1,x] == label and not mask[z,y-1,x] :
            seeds.append((z,y-1,x))
        if x+1<s[2] and seg[z,y,x+1] == label and not mask[z,y,x+1] :
            seeds.append((z,y,x+1))
        if x-1>=0    and seg[z,y,x-1] == label and not mask[z,y,x-1] :
            seeds.append((z,y,x-1))
    return seg2, mask

#%% relabel by connectivity analysis
def relabel1N(seg):
    print 'relabel by connectivity analysis ...'
    # masker for visiting
    mask = np.zeros(seg.shape, dtype=np.bool)
    mask[seg==0] = True

    s = np.array(seg.shape)
    seg2 = np.copy(seg)
    # relabel ID
    relid = 0
    for z in xrange(s[0]):
        for y in xrange(s[1]):
            for x in xrange(s[2]):
                if mask[z,y,x]:
                    continue
                relid += 1
                label = seg[z,y,x]
                # flood fill
                seg2, mask = dfs(seg, seg2, mask, relid, label, s, z,y,x)
    print "number of segments: {}-->{}".format( np.unique(seg).shape[0], np.unique(seg2).shape[0] )
    return seg2

def add_item(con, key, value):
    if (not con.has_key(key)) or con[key]<value:
        con[key] = value
    return con
def build_region_graph( seg, affin ):
    con = {}
    Nz,Ny,Nx = seg.shape
    for z in xrange(1, Nz):
        for y in xrange(1, Ny):
            for x in xrange(1, Nx):
                obj1 = seg[z,y,x]
                if seg[z,y,x] and seg[z-1,y,x] and seg[z,y,x]!=seg[z-1,y,x]:
                    con = add_item(con,frozenset([obj1, seg[z-1,y,x]]), affin[2,z,y,x])
                if seg[z,y,x] and seg[z,y-1,x] and seg[z,y,x]!=seg[z,y-1,x]:
                    con = add_item(con,frozenset([obj1, seg[z,y-1,x]]), affin[1,z,y,x])
                if seg[z,y,x] and seg[z,y,x-1] and seg[z,y,x]!=seg[z,y,x-1]:
                    con = add_item(con,frozenset([obj1, seg[z,y,x-1]]), affin[0,z,y,x])
    return con

#%% estimate the connection probability, construct the dendrogram
def build_dend(seg, affin):
    # build region graph
    print 'build region graph ...'
#    con = build_region_graph( seg, affin )
    import c_relabel
    con = c_relabel.build_region_graph(seg, affin)
    print 'post processing ...'
    # get minimum spanning tree
    values = np.asarray( con.values() )
    r1 = np.empty(values.shape, dtype='uint32')
    r2 = np.empty(values.shape, dtype='uint32')
    for idx, key in enumerate(con.keys()):
        r1[idx], r2[idx] = key
    # eleminate the dend with low affinity
    mask = (values > min(gws_low, gws_dust_low))
    values = values[ mask ]
    r1 = r1[ mask ]
    r2 = r2[ mask ]
    # sort the dendrogram to descending order
    index = np.argsort(values)[::-1]
    values = values[index]
    r1 = r1[index]
    r2 = r2[index]

    # hierarchical clustering
    # cluster id vector
    cids = np.zeros( values.shape, dtype='uint32' )
    # index of cluster
    cind = 0
    dend = []
    dendValues = []
    for k in xrange( values.shape[0] ):
        # cluster id
        cid1 = cids[ r1[k] ]
        cid2 = cids[ r2[k] ]

        if cid1!=0 and cid2!=0 and cid1==cid2:
            # already in the same cluster
            continue
        elif cid1!=0 and cid2!=0 and cid1!=cid2:
            # both are nonzero and unequal, merge two clusters
            cids[ cids==cid2 ] = cid1
        elif cid1==0 and cid2!=0:
            cids[ r1[k] ] = cid2
        elif cid1!=0 and cid2==0:
            cids[ r2[k] ] = cid1
        elif cid1==0 and cid2==0:
            cind += 1
            cids[ r1[k] ] = cind
            cids[ r2[k] ] = cind
        # append the dend and dendValues
        dend.append(np.array([ r1[k], r2[k] ]))
        dendValues.append( values[ k ] )

    # transform to numpy array
    dend = np.asarray( dend ).transpose()
    dendValues = np.asarray( dendValues )

    return dend, dendValues

# topological depth first search
def topological_dfs( dend, con, seed, torder, topologically_next ):
    seeds = list([seed])
    while seeds:
        seed = seeds.pop()
        topologically_next += 1
        torder[seed] = topologically_next
        # find all the neibours
        _, neighbours = con.getrow( seed ).nonzero()   # ignore the first row index
        for ni in neighbours:
            if not torder[ni]:
                seeds.append(ni)
    return torder, topologically_next

def topological_sort(dend):
    Ns = dend.max() + 1
    # topological order
    torder = np.zeros(Ns, dtype='uint32')

    con = scipy.sparse.lil_matrix((Ns,Ns), dtype = 'bool')
    # build connectivity of MST
    for d0,d1 in zip(dend[0,:], dend[1,:]):
        con[d0, d1] = con[d1, d0] = True
    con = con.tocsr()
    # topological order labeling by depth first search
    topologically_next = 0
    for k in xrange(1, Ns):
        if not torder[k]:
            torder, topologically_next = topological_dfs( dend, con, k, torder, topologically_next )
    # resort dend according to topological order
    for k in xrange(dend.shape[1]):
        if torder[ dend[0,k] ] < torder[ dend[1,k] ]:
            dend[0,k], dend[1,k] = dend[1,k], dend[0,k]

    return dend

def relabel(seg, affin):
#    seg2 = relabel1N(seg)
#    seg2 = np.copy(seg)
    import c_relabel
    seg2 = c_relabel.relabel1N(seg)
    dend, dendValues = build_dend(seg2, affin)
    dend = topological_sort(dend)
    return seg2, dend, dendValues

if __name__ == '__main__':

    h5file_m = '../znn_merged_matlab.Th-900.Tl-300.Ts-400.Te-250.segm.h5'

    #%% read data
    fm = h5py.File(h5file_m, 'r')
    seg_m = np.asarray(fm['/main'])
    dend_m = np.asarray(fm['/dend'])
    dendValues_m = np.asarray(fm['/dendValues'])
    fm.close()

    f = h5py.File( affin_file, 'r' )
    affin = np.asarray( f['/main'] )
    f.close()
    f = h5py.File( chann_file, 'r' )
    chann = np.asarray( f['/main'] )
    f.close()

    #%%
    seg2, dend, dendValues = relabel(seg_m, affin)

    print "max: {}, number: {}, mst size: {}".format(seg2.max(), np.unique(seg2).shape[0], len(dendValues))
    print ""

    #%% validation
    print "validation ..."
    # establish a sparse connectivity matrix
    Nal = dend_m.max()
    acon = scipy.sparse.lil_matrix((Nal+1,Nal+1), dtype=affin.dtype)
    acon[dend_m[0,:], dend_m[1,:]] = dendValues_m
    acon[dend_m[1,:], dend_m[0,:]] = dendValues_m

    # label correspondance
    Nl = len(np.unique(seg2))
    corr = np.zeros((Nl), dtype='uint32')
    corr[seg2] = seg_m

    # compare the dend values
    for k, dv in enumerate(dendValues):
        l1,l2 = dend[:,k]
        # the corresponding label of all
        al1 = corr[l1]
        al2 = corr[l2]
        # the value of all
        adv = acon[al1,al2]
#        if dv == adv:
#            print "k:{},    local: {}--{},  global: {}--{},     same value: {}".format(k, l1, l2, al1, al2, dv)
#        else:
#            print "k:{},    local: {}--{},  global: {}--{},     value: {}-->{}".format(k, l1,l2, al1, al2, dv, adv)

    #%% visualization
    zi = 12
    plt.subplot(221)
    plt.imshow(chann[zi,:,:], cmap='gray', interpolation='nearest')
    plt.xlabel('channel data')
    plt.subplot(222)
    plt.imshow(affin[0,zi,:,:])
    plt.xlabel('affinity map')
    plt.subplot(223)
    emirt.show.random_color_show(seg_m[zi,:,:], mode='mat')
    #plt.imshow(seg[zi,:,:]==56)
    plt.xlabel('original segmentation')
    plt.subplot(224)
    emirt.show.random_color_show(seg2[zi,:,:], mode='mat')
    #plt.imshow(seg2[zi,:,:]==30)
    plt.xlabel('relabeled segmentation')

    #%% write to a h5 file for omnifying
    f = h5py.File('../relabel.h5', 'w')
    f.create_dataset('/main', data=seg2, dtype='uint32')
    f.create_dataset('/dend', data=dend, dtype='uint32')
    f.create_dataset('/dendValues', data=dendValues, dtype='single')
    f.close()
