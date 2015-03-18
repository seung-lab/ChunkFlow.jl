import numpy
import h5py
import znn
import os
import json

from global_vars import *
from tqdm import tqdm


#Open the merge watershed file
segmentation = h5py.File('../watershed/data/watershed_merged.hdf5', "r" )
dims = numpy.asarray(segmentation['/main'].shape)


#Open the channel data
channel = h5py.File('../omnify/channel.hdf5','r')


if not os.path.exists('../omnify/data'):
     os.makedirs('../omnify/data')
else:
	#For test
	import shutil
	shutil.rmtree('../omnify/data')
	os.makedirs('../omnify/data')
dims =  numpy.array([647, 3000 , 3000])

divs = numpy.array([3,3,3])
overlap = numpy.array([128, 128 , 128])
width = ((dims / 128) / divs ) * 128
width[width < 128] = 128


if numpy.all(overlap == width):
	divs = numpy.array([1,1,1])

chunks = []
for z_chunk in range(0, divs[0]):
	if z_chunk == 0:
		z_chunk_min = 0
	else:
		z_chunk_min = z_chunk_min - overlap[0]

	z_chunk_max = z_chunk_min + width[0]

	for y_chunk in range(0 , divs[1]):
		if y_chunk == 0:
			y_chunk_min = 0
		else:
			y_chunk_min = y_chunk_min - overlap[1] 


		y_chunk_max = y_chunk_min + width[1]


		for x_chunk in range(0, divs[2]):
			if x_chunk == 0:
				x_chunk_min = 0
			else:
				x_chunk_min = x_chunk_min - overlap[2] 

			x_chunk_max = x_chunk_min + width[2]
			cfrom = numpy.array([z_chunk_min, y_chunk_min, x_chunk_min])
			cfrom[cfrom < 0] = 0
			cto = numpy.array([z_chunk_max, y_chunk_max, x_chunk_max]) 
			cto = numpy.minimum(cto, dims)

			filename = "z{0}-y{1}-x{2}".format(z_chunk, y_chunk, x_chunk)
			chunk = {'x_min': cfrom[2], 'x_max':cto[2], 'y_min': cfrom[1], 'y_max':cto[1], 'z_min':cfrom[0] , 'z_max':cto[0],'filename':filename }
			chunks.append(chunk)
			print chunk

			x_chunk_min = x_chunk_max
		y_chunk_min = y_chunk_max
	z_chunk_min = z_chunk_max


#Create bash file with all the jobs to be run
jobs = open('scheduleOmnification.sh','w')


for c in tqdm(chunks):

	#Make a folder which will contain this chunk
	os.makedirs('../omnify/data/{0}'.format(c['filename']))

	#save chunk information as a file
	with open('../omnify/data/{0}/absolute_position.json'.format(c['filename']), 'wb') as fp:
		json.dump(c, fp)

	#save main segmentation chunk
	with h5py.File('../omnify/data/{0}/segmentation.hdf5'.format(c['filename']), "w" ) as chunk_seg:
		main_dset = segmentation['/main'][c['z_min']:c['z_max'], c['y_min']:c['y_max'], c['x_min']:c['x_max']]
		old_shape = main_dset.shape
		main_dset = main_dset.flatten()

		#save dendogram
		dendogram = segmentation['/dend']
		dendValues = segmentation['/dendValues']

		# truncate the dend
		unique_ids = numpy.unique(main_dset)
		id_map = dict(zip(unique_ids, range(len(unique_ids))))


		truncated_dend = []
		truncated_dendValues = []

		new_id = 0
		for row in range(dendogram.shape[1]):
			left_id = dendogram[0,row]
			right_id = dendogram[1,row]
			if left_id in unique_ids and right_id in unique_ids:				

				truncated_dendValues.append(dendValues[row])
				truncated_dend.append(numpy.array([id_map[left_id], id_map[right_id]]))

		for index in range(len(main_dset)):
			main_dset[index] = id_map[main_dset[index]]

		main_dset = main_dset.reshape(old_shape)
		chunk_seg.create_dataset('/main', data=main_dset , dtype='uint32' )
		chunk_seg.create_dataset('/dend', data=numpy.array(truncated_dend).transpose(), dtype='uint32' )
		chunk_seg.create_dataset('/dendValues', data=truncated_dendValues , dtype='float32' )
	
	#Save the channel chunk
	with h5py.File('../omnify/data/{0}/channel.hdf5'.format(c['filename']), "w" ) as chunk_chann:
		main_dset = channel['/main'][c['z_min']:c['z_max'], c['y_min']:c['y_max'], c['x_min']:c['x_max']]
		chunk_chann.create_dataset('/main', data=main_dset , dtype='float32' )

	#Create omni run files
	resolution = numpy.array([7, 7 , 40])

	with open('../omnify/data/{0}/omnify.cmd'.format(c['filename']), 'w') as fcmd:
		fcmd.write("""create:../../../trace/{0}.omni
loadHDF5chann:channel.hdf5
setChanResolution:1,{1},{2},{3}
loadHDF5seg:segmentation.hdf5
setSegResolution:1,{1},{2},{3}
setChanAbsOffset:1,{4},{5},{6}
setSegAbsOffset:1,{4},{5},{6}
mesh
quit""".format(c['filename'], resolution[0], resolution[1], resolution[2], c['x_min']*resolution[0], c['y_min']*resolution[1], c['z_min']*resolution[2]))

	with open('../omnify/data/{0}/run.sh'.format(c['filename']), 'w') as runfile:
		runfile.write( '../../omnify.sh --headless --cmdfile=omnify.cmd')

		#make this file executable
		st = os.stat(runfile.name)
		os.chmod(runfile.name, st.st_mode | 0111 )


	#Add run.sh file to the job list
	#For production
	#The -r argument instructs the queueing system to re-execute the same job on a different worker node 
	#if the currently running worker node fails or is terminated. With all jobs marked as re-runnable 
	#a given spot instance can be terminated and any running jobs on the instance will simply be restarted 
	#on a different worker. This approach does not resume a job where it left off before it was interrupted,
	#however, it does ensure that it will eventually be completed if and when resources are available. 
	#jobs.write('qsub -r y -V -b y -cwd ./data/{0}/trainning_spec/run.sh \n'.format(c['filename']))
	#For test
	jobs.write('../omnify/data/{0}/run.sh \n'.format(c['filename']))

segmentation.close()
channel.close()


#Close jobs and make it executable
jobs.close()
st = os.stat(jobs.name) 
os.chmod(jobs.name, st.st_mode | 0111)