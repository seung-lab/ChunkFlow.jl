import math
import numpy
import h5py
import pprint
import os
import stat  
from PIL import Image
from PIL.ImageDraw import Draw

#Custom packages
import znn
from stack import Stack

#Set the resources for the machine in which znn will be run
memory = 10  #gb  
nthreads = 8 #virtual cores

#How many chuncks do we want z,y,x
divs = numpy.array([1, 10, 10])

#Read aligned stack
stack = Stack()

#Save dimension of the stack z,y,x
dims = stack.getStackDimensions()

# We will apply two neural networks (stage1 and stage2)
# We need to know the field of view of each stage, and the "effective" field of view
# i.e. the FoV combined of both stages
fov_stage1 = numpy.array([1,109,109])
fov_stage2 = numpy.array([9,65,65])
fov_effective = numpy.array([8,172,172])



#Estimate how long will it take, and how much computation is wasted because of overlapping
computedSize = dims + fov_effective * (divs - 1)
print "Besides the size of the stack is ",dims, " because of overlapping we will compute", computedSize
speed = 7500 #voxels/second
print "it will take about " , numpy.prod(computedSize)/numpy.prod(divs) / speed / 3600.0 , " hours for the 2 stages of ZNN "
print "with efficiency ",  numpy.prod(dims) / float(numpy.prod(computedSize)) * 100.0 , "%"


#We will now compute the size of each chunck and store it in chunks' list.
chunks = []
div_size = (dims - fov_effective) / divs

#Make sure the size of the chunk is larger than the field of view
assert numpy.all(div_size > fov_effective)

z_min =0; z_max = fov_effective[0]
for z in range(divs[0]):

	if z == 0:
		z_min = 0
	else:
		z_min = z_min + div_size[0]

	if z == divs[0] - 1:
		z_max = dims[0]
	else:
		z_max = z_max + div_size[0]

	#Do same thing as z, but for y_axis
	y_min =0; y_max = fov_effective[1]
	for y in range(divs[1]):	
		if y == 0:
			y_min = 0
		else:
			y_min = y_min + div_size[1]

		if y == divs[1] - 1:
			y_max = dims[1]
		else:
			y_max = y_max + div_size[1]

		#Do same thing as z,y, but for x-axis
		x_min =0; x_max = fov_effective[2]
		for x in range(divs[2]):
			if x == 0:
				x_min = 0
			else:
				x_min = x_min + div_size[2]

			if x == divs[2] - 1:
				x_max = dims[2]
			else:
				x_max = x_max + div_size[2]

			#Save everything in chunks' list
			filename = "z{0}-y{1}-x{2}".format(z,y,x)
			chunk = {'x_min': x_min, 'x_max':x_max, 'y_min': y_min, 'y_max':y_max, 'z_min':z_min , 'z_max':z_max,'filename':filename }
			chunks.append(chunk)



#Plot chunk
print '\n\n\n'
pp = pprint.PrettyPrinter()
pp.pprint(chunks)

#Save an image which displays the chunk overlapping
img = Image.new("RGBA", (dims[1],dims[2]),(255,255,255,255)) # We don't draw z
draw = Draw(img)

for chunk in chunks:
	#Draw in red the output of znn, this output should cover the hole volume without overlap
	draw.rectangle(((chunk['x_min']+fov_effective[2]/2,chunk['y_min']+fov_effective[1]/2),(chunk['x_max']-fov_effective[2]/2, chunk['y_max']-fov_effective[1]/2)),outline = 'red')
	
	#We also draw the input to znn in blue, this should overlap
	draw.rectangle(((chunk['x_min'],chunk['y_min']), (chunk['x_max'], chunk['y_max'])), outline = "blue" )

#We save this image
img.save('./image.png')


#We will now use the chunks position to crop the stack and to save it in ./data folder, with al required files to run znn on them
if not os.path.exists('../data'):
     os.makedirs('../data')
else:
	#for test
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



for c in chunks:

	#Make a folder which will contain this chunk
	os.makedirs('../data/{0}'.format(c['filename']))

	#We create a folder to store the chuncked stack as a raw file of double
	os.makedirs('../data/{0}/input'.format(c['filename']))
	#Save absolute position of the input as a json file
	znn.save_input_size(c)

	#Get chunck and save it to disk
	chunk = stack.getChunk(c['z_max'], c['z_min'], c['y_max'], c['y_min'], c['x_max'], c['x_min'])
	chunk.tofile('../data/{0}/input/input'.format(c['filename']))
	sz = numpy.asarray(chunk.shape).astype(numpy.uint32)
	sz.tofile('../data/{0}/input/input.size'.format(c['filename']))

	#We also create an empty directoy in where znn will save the output
	os.makedirs('../data/{0}/output'.format(c['filename']))
	#Save the absolute position as a json file
	znn.save_output_size(c,fov_effective)

	#Create data specification folder which contains the files for specifiying the dataset
	#We have two inputs because of having, 2 neural nets (stage1, stage2)
	os.makedirs('../data/{0}/data_spec'.format(c['filename']))
	znn.stage1Data(c)
	znn.stage2Data(c)


	#Create trainning specification folder which specifies the parameters for the forward pass
	#Again we have two files because of the two stage forward pass
	os.makedirs('../data/{0}/trainning_spec'.format(c['filename']))
	    
	chunk_stage1 = numpy.array([c['z_max']-c['z_min'],c['y_max']-c['y_min'],c['x_max']-c['x_min']])
	chunk_stage2 = znn.stage1Train(c,chunk_stage1,fov_stage1, nthreads, memory)
	znn.stage2Train(c,chunk_stage2,fov_stage2, nthreads, memory)

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
	#production
	jobs.write('qsub -V -b y -cwd ./data/{0}/trainning_spec/run.sh \n'.format(c['filename']))
	#test
	#jobs.write('./data/{0}/trainning_spec/run.sh \n'.format(c['filename']))


#Close jobs and make it executable
jobs.close()
st = os.stat(jobs.name) 
os.chmod(jobs.name, st.st_mode | 0111)