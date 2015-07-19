#!/usr/bin/env python
__doc__ = '''
2D Rand Error Between ZNN Volumes

 This module computes the 2D Rand Error between
two ZNN volumes. It also saves a volume for each of the inputs,
which contains the connected components found by 4-connectivity analysis.

Inputs:

	-Network Output Filename
	-Label Filename
	-Threshold for the network output
	-Whether to save connected component volumes (opt) (flag)
	
Main Outputs:

	-Reports rand error via a print
	-Saves connected component volumes to disk

Nicholas Turner, Jingpeng Wu June 2015
'''

import timeit
import argparse
import numpy as np
import io
from cynn import relabel, overlap_matrix
from os import path

def threshold_volume(vol, threshold):
	return (vol > threshold).astype('uint32')

def rand_error(om):
	'''Calculates the rand error of an unnormalized (raw counts) overlap matrix'''

	counts1 = om.sum(1)
	counts2 = om.sum(0)

	#float allows easier division
	N = float(counts1.sum())

	a_term = np.sum(np.square(counts1)) / (N ** 2)
	b_term = np.sum(np.square(counts2)) / (N ** 2)

	#p term requires a bit more work with sparse matrix
	sq_vals = np.copy(om.data) ** 2
	p_term = np.sum(sq_vals) / (N ** 2)

	return a_term + b_term - 2*p_term

def main(vol_fname, label_fname, threshold=0.5, save=False):

	print "Loading Data..."
	vol = io.znn_img_read(vol_fname)
	label = io.znn_img_read(label_fname)

	if len(vol.shape) > 3:
		if vol.shape[0] > 2:
			vol = np.argmax(vol, axis=0).astype('uint32')
		else:
			vol = vol[1,:,:,:]

			print "Thresholding output volume..."
			vol = threshold_volume(vol, threshold)

	print "Labelling connected components in volume..."
	start = timeit.default_timer()
	vol_cc = relabel.relabel1N(vol)
	end = timeit.default_timer()
	print "Labelling completed in %f seconds" % (end-start)
	print
	print "Labelling connected components in labels..."
	start = timeit.default_timer()
	label_cc = relabel.relabel1N(label.astype('uint32'))
	end = timeit.default_timer()
	print "Labelling completed in %f seconds" % (end-start)

	if save:
		print "Saving labelled connected components..."
		io.znn_img_save(vol_cc.astype(float), 'cc_{}'.format(path.basename(vol_fname)))
		io.znn_img_save(label_cc.astype(float), 'cc_{}'.format(path.basename(label_fname)))

	print
	print "Finding overlap matrix..."
	start = timeit.default_timer()
	om = overlap_matrix.overlap_matrix(vol_cc, label_cc)
	end = timeit.default_timer()
	print "Matrix Calculated in %f seconds" % (end-start)

	print "Calculating Rand Error..."
	RE = rand_error(om)

	print "Rand Error: "
	print RE

	return vol_cc

if __name__ == '__main__':

	parser = argparse.ArgumentParser(
		description=__doc__,
		formatter_class=argparse.RawDescriptionHelpFormatter)

	parser.add_argument('output_filename', 
		help="Filename of the output image")
	parser.add_argument('label_filename',
		help="Filename of the labels for comparison")
	parser.add_argument('threshold',
		nargs='?',default=0.5, type=float,
		help="Threshold for generating binary image")
	parser.add_argument('-no_save',
		default=True, action='store_false')

	args = parser.parse_args()

	main(args.output_filename,
		 args.label_filename,
		 args.threshold,
		 args.no_save)
