
'''
make the label id unique, do not variate among different running of watershed
'''

import cython
import numpy as np
cimport numpy as np


cdef extern void make_unique( int* volout, const int* volume, unsigned int volume_size,\
                  int* paiout, const int* pairs,  unsigned int pairs_size  )

@cython.boundscheck(False)
@cython.wraparound(False)

def makeUnique( np.ndarray[int, ndim=3, mode="c"] seg     not None, \
                np.ndarray[int, ndim=2, mode="c"] dend    not None):
                    
    cdef unsigned int seg_size  = seg.flatten().shape[0]
    cdef unsigned int dend_size   = dend.flatten().shape[0]
    
    cdef np.ndarray[int, ndim=3, mode="c"] segout = np.copy(seg)
    cdef np.ndarray[int, ndim=2, mode="c"] dendout = np.copy(dend)
        
    make_unique( &segout[0,0,0], &seg[0,0,0], seg_size, &dendout[0,0], &dend[0,0],  dend_size  )
    return segout, dendout