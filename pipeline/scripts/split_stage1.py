#!/usr/bin/python

import sys
import numpy

chunk_dir = sys.argv[1]
print 'splitting stage1 in half'
znn_chunk_size = numpy.fromfile('../znn/data/{0}/output/stage11.size'.format(chunk_dir), dtype='uint32')[::-1]
znn_chunk_affinity =  numpy.fromfile('../znn/data/{0}/output/stage11'.format(chunk_dir), dtype='double').reshape(znn_chunk_size)

znn_chunk_affinity[1,:,:,:].tofile('../znn/data/{0}/output/stage11'.format(chunk_dir))
znn_chunk_size[1:4][::-1].tofile('../znn/data/{0}/output/stage11.size'.format(chunk_dir))
