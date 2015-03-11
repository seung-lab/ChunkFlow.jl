import math
import numpy
import h5py
import os
import stat  


#Custom packages
import znn
from stack import Stack
from global_vars import *

#It computes the optimal disposition of chunks try to reduce waste computation because of overlaps
#divs = znn.optimal_divs()
divs = numpy.array([2 ,2 ,2])

#Give a dispositions of chunks, it compute the absolute position in voxels to have the right overlapping
chunks = znn.chunk_sizes(divs)

#We will now use the chunks position to crop the stack and to save it in ./data folder, with al required files to run znn on them
if not os.path.exists('../data'):
     os.makedirs('../data')
else:
	#For test
	import shutil
	shutil.rmtree('../data')
	os.makedirs('../data')

    #For production
    #raise Exception('folder already exists')

#Create bash file with all the jobs to be run
jobs = open('../scheduleJobs.sh','w')

#check if znn is compiled, if not, add it to the script
if not os.path.isfile('../znn-release/bin/znn'):
	jobs.write('cd ./znn-release/\n')
	jobs.write('make\n')
	jobs.write('cd ../\n')


#Read aligned stack
stack = Stack()

#size to crop is 1 pixel less than the field of view
crop_effective = fov_effective - 1

for c in chunks:

	#Make a folder which will contain this chunk
	os.makedirs('../data/{0}'.format(c['filename']))

	#We create a folder to store the chuncked stack as a raw file of double
	os.makedirs('../data/{0}/input'.format(c['filename']))
	#Save absolute position of the input as a json file
	znn.save_input_size(c)

	#Get chunck and save it to disk
	chunk = stack[c['z_min']:c['z_max'], c['y_min']:c['y_max'], c['x_min']:c['x_max']]
	
	chunk.tofile('../data/{0}/input/input'.format(c['filename']))
	sz = numpy.asarray(chunk.shape).astype(numpy.uint32)[::-1]
	sz.tofile('../data/{0}/input/input.size'.format(c['filename']))

	#We also create an empty directoy in where znn will save the output
	os.makedirs('../data/{0}/output'.format(c['filename']))
	#Save the absolute position as a json file
	znn.save_output_size(c,crop_effective)

	#Create data specification folder which contains the files for specifiying the dataset
	#We have two inputs because of having, 2 neural nets (stage1, stage2)
	os.makedirs('../data/{0}/data_spec'.format(c['filename']))
	znn.stage1Data(c)
	znn.stage2Data(c)

	#Create trainning specification folder which specifies the parameters for the forward pass
	#Again we have two files because of the two stage forward pass
	os.makedirs('../data/{0}/trainning_spec'.format(c['filename']))
	    
	chunk_stage1 = numpy.array([c['z_max']-c['z_min'],c['y_max']-c['y_min'],c['x_max']-c['x_min']])
	chunk_stage2 = znn.stage1Train(c,chunk_stage1,fov_stage1)
	znn.stage2Train(c,chunk_stage2,fov_stage2)

	#Create a bash script to run both stages together, we will add this script to the jobs list
	#This way both stages will be run in the same node
	#This is to prevent that if we have more nodes than chuncks, stages2 will start running
	#Before stage1 finishes
	
	with open('../data/{0}/trainning_spec/run.sh'.format(c['filename']),'w') as runfile:

		run = """#!/bin/bash
		./znn-release/bin/znn --options=./data/{0}/trainning_spec/stage1.spec --test_only=1
		./znn-release/bin/znn --options=./data/{0}/trainning_spec/stage2.spec --test_only=1
		""".format(c['filename'])

		runfile.write(run)

	#make this file executable
	st = os.stat('../data/{0}/trainning_spec/run.sh'.format(c['filename']))
	os.chmod('../data/{0}/trainning_spec/run.sh'.format(c['filename']), st.st_mode | 0111 )

	#Add run.sh file to the job list
	#For production
	#The -r argument instructs the queueing system to re-execute the same job on a different worker node 
	#if the currently running worker node fails or is terminated. With all jobs marked as re-runnable 
	#a given spot instance can be terminated and any running jobs on the instance will simply be restarted 
	#on a different worker. This approach does not resume a job where it left off before it was interrupted,
	#however, it does ensure that it will eventually be completed if and when resources are available. 
	jobs.write('qsub -r -V -b y -cwd ./data/{0}/trainning_spec/run.sh \n'.format(c['filename']))
	#For test
	#jobs.write('./data/{0}/trainning_spec/run.sh \n'.format(c['filename']))


#Close jobs and make it executable
jobs.close()
st = os.stat(jobs.name) 
os.chmod(jobs.name, st.st_mode | 0111)