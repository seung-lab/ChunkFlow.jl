import numpy
import h5py
import znn
import os
import json

from global_vars import *


divs = numpy.array([1,1,2])

overlap = numpy.array([2, 2 ,2])

#Open the merge watershed file
segmentation = h5py.File('../watershed/data/watershed_merged.hdf5', "r" )
dims = segmentation['/main'].shape

#Open the channel data
channel = h5py.File('../omnify/channel.hdf5','r')


if not os.path.exists('../omnify/data'):
     os.makedirs('../omnify/data')
else:
	#For test
	import shutil
	shutil.rmtree('../omnify/data')
	os.makedirs('../omnify/data')


for c in znn.chunk_sizes(dims, divs, overlap):

	#Make a folder which will contain this chunk
	os.makedirs('../omnify/data/{0}'.format(c['filename']))

	#save chunk information as a file
	with open('../omnify/data/{0}/absolute_position.json'.format(c['filename']), 'wb') as fp:
		json.dump(c, fp)

	#save main segmentation chunk
	with h5py.File('../omnify/data/{0}/segmentation.hdf5'.format(c['filename']), "w" ) as chunk_seg:
		main_dset = segmentation['/main'][c['z_min']:c['z_max'], c['y_min']:c['y_max'], c['x_min']:c['x_max']]

		main_dset_relabeled = numpy.copy(main_dset)

		#save dendogram
		dendogram = segmentation['/dend']
		dendValues = segmentation['/dendValues']

		# truncate the dend
		unique_ids = numpy.unique(main_dset)
		truncated_dend = []
		truncated_dendValues = []

		id_map = {}

		new_id = 0
		for row in range(dendogram.shape[1]):
			left_id = dendogram[0,row]
			right_id = dendogram[1,row]
			if left_id in unique_ids and right_id in unique_ids:				
				truncated_dendValues.append(dendValues[row])

				if left_id in id_map:
					map_left_id = id_map[left_id]
				else:
					map_left_id = new_id
					id_map[left_id] = new_id
					new_id += 1

				if right_id in id_map:
					map_right_id = id_map[right_id]
				else:
					map_right_id = new_id
					id_map[right_id] = new_id
					new_id += 1

				truncated_dend.append(numpy.array([map_left_id, map_right_id]))
				main_dset_relabeled[ main_dset == left_id] = map_left_id
				main_dset_relabeled[ main_dset == right_id] = map_right_id

		chunk_seg.create_dataset('/main', data=main_dset_relabeled , dtype='uint32' )
		chunk_seg.create_dataset('/dend', data=numpy.array(truncated_dend).transpose(), dtype='uint32' )
		chunk_seg.create_dataset('/dendValues', data=truncated_dendValues , dtype='float32' )
	
	#Save the channel chunk
	with h5py.File('../omnify/data/{0}/channel.hdf5'.format(c['filename']), "w" ) as chunk_chann:
		main_dset = channel['/main'][c['z_min']:c['z_max'], c['y_min']:c['y_max'], c['x_min']:c['x_max']]
		chunk_chann.create_dataset('/main', data=main_dset , dtype='float32' )

	#Create omni run files
	with open('../omnify/data/{0}/omnify.cmd'.format(c['filename']), 'w') as fcmd:
		fcmd.write("""create:../../../trace/{0}.omni
loadHDF5chann:channel.hdf5
setChanResolution:1,7,7,40
loadHDF5seg:segmentation.hdf5
setSegResolution:1,7,7,40
mesh
quit""".format(c['filename']))

	with open('../omnify/data/{0}/run.sh'.format(c['filename']), 'w') as runfile:
		runfile.write( '../../omnify.sh --headless --cmdfile=omnify.cmd')

		#make this file executable
		st = os.stat(runfile.name)
		os.chmod(runfile.name, st.st_mode | 0111 )

segmentation.close()
channel.close()