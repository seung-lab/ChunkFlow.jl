import numpy as np 

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

	vol = vol - np.min(vol)
	vol = vol / np.max(vol)

	return vol
