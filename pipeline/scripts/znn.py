import math
import numpy
import json
from PIL import Image
from PIL.ImageDraw import Draw
import pprint


from global_vars import *
from stack import Stack


def optimal_divs():
	#size to crop is 1 pixel less than the field of view
	crop_effective = fov_effective - 1

	#Read aligned stack
	stack = Stack()

	#Save dimension of the stack z,y,x
	dims = stack.shape

	#How many chuncks do we should have z,y,x
	min_timeRequired = numpy.float('inf')
	for z in range(1,max_nodes+1):
		for y in range(1,max_nodes+1):
			for x in range(1,max_nodes+1):
				
				if x*y*z > max_nodes:
					continue

				test_divs = numpy.array([z,y,x])
				timeRequired = numpy.prod( (dims+crop_effective*(test_divs-1)) / test_divs)
				if timeRequired < min_timeRequired:
					min_timeRequired = timeRequired
					divs = test_divs



	return divs

def chunk_sizes(dims, divs, overlap):

	#We will now compute the size of each chunck and store it in chunks' list.
	chunks = []
	div_size = (dims - overlap) / divs

	#Make sure the size of the chunk is larger than the field of view
	if numpy.any(div_size < 0):
		raise Exception('Chunks are too small', div_size )

	z_min =0; z_max = overlap[0]
	for z in range(divs[0]):

		if z == 0:
			z_min = 0
		else:
			z_min = z_min + div_size[0]

		if z == divs[0] - 1:
			z_max = dims[0]
		else:
			z_max = z_max + div_size[0]#Set the resources for the machine in which znn will be run


		#Do same thing as z, but for y_axis
		y_min =0; y_max = overlap[1]
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
			x_min =0; x_max = overlap[2]
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
	pp = pprint.PrettyPrinter()
	pp.pprint(chunks)

	#Save an image which displays the chunk overlapping
	print dims
	img = Image.new("RGBA", (dims[2],dims[1]),(255,255,255,255)) # We don't draw z
	draw = Draw(img)

	for chunk in chunks:
		#Draw in red the output of znn, this output should cover the hole volume without overlap
		draw.rectangle(((chunk['x_min']+overlap[2]/2,chunk['y_min']+overlap[1]/2),(chunk['x_max']-overlap[2]/2, chunk['y_max']-overlap[1]/2)),outline = 'red')
		
		#We also draw the input to znn in blue, this should overlap
		draw.rectangle(((chunk['x_min'],chunk['y_min']), (chunk['x_max'], chunk['y_max'])), outline = "blue" )

	#We save this image
	img.save('./image.png')

	return chunks



cache = dict()
def stage1Data(c):
	with  open('../znn/data/{0}/data_spec/stage1.1.spec'.format(c['filename']),'w') as myfile:

		template = """[INPUT1]
path={path_input}
size={size}
pptype=standard2D"""

		context = {
			"path_input":'../znn/data/{0}/input/input'.format(c['filename']), 
			"size": '{0},{1},{2}'.format(c['x_max']-c['x_min'],c['y_max']-c['y_min'],c['z_max']-c['z_min'])
		} 
		myfile.write(template.format(**context)) 

def stage2Data(c):
	with  open('../znn/data/{0}/data_spec/stage2.1.spec'.format(c['filename']),'w') as myfile:

		template = """[INPUT1]
path={path_input}
size={size}
pptype=standard2D

[INPUT2]
path={path_output_stage1}
offset=54,54,0
pptype=transform
ppargs=-1,1"""

		context = {
			"path_input":'../znn/data/{0}/input/input'.format(c['filename']), 
			"size": '{0},{1},{2}'.format(c['x_max']-c['x_min'],c['y_max']-c['y_min'],c['z_max']-c['z_min']),
			"path_output_stage1":'../znn/data/{0}/output/stage11'.format(c['filename']),  #this is the path to outname
		} 
		myfile.write(template.format(**context)) 

def optimal_outsz(input_size, fov_in, architecture_multiplier= 5 * 10**5, div_precision = 75):
	#So based on the chunk size (`input_size`), and the fov of the current stage `fov_in`
	#we do a grid search from [1,1,1] to `chunk_size` which is the output size of the chunk 
	#and it choose the best_outz based on the metric `score`
	
	#implement a cache because this takes long to run
	args = {'input_size':input_size.tostring(), 'fov_in':fov_in.tostring(),  'architecture_multiplier':architecture_multiplier , 'div_precision':div_precision}
	args = frozenset(args.items())
	if args in cache:
		print 'znn outsz is ' , cache[args]
		return cache[args]

	min_score = numpy.float('inf')
	best_outsz = None

	#We don't want to overright input_size
	chunk_size = input_size.astype(float) - fov_in + 1
	fov = fov_in.copy().astype(float)

	for z in numpy.linspace(1, chunk_size[0] , div_precision , dtype=int):
		for y in numpy.linspace(1, chunk_size[1] , div_precision , dtype=int):
			for x in  numpy.linspace(1, chunk_size[2] ,div_precision , dtype=int):

				outsz = numpy.array([z,y,x])
				memory_estimated = numpy.prod(outsz + fov - 1) * architecture_multiplier

			
				if memory_estimated > memory:
					continue


				computation_done = numpy.prod(numpy.ceil(chunk_size/outsz) * (outsz + fov - 1))

				if computation_done < min_score:
					min_score = computation_done
					best_outsz = outsz

	if best_outsz is None:
		raise Exception('There is not enough memory even for the smallest outsz')
	else:
		print 'znn outsz is ' , best_outsz


	cache[args] = best_outsz
	return best_outsz


def stage1Train(c,input_size,fov):

	outsz = optimal_outsz(input_size , fov, architecture_multiplier= 2.4 * 10**5)

	with  open('../znn/data/{0}/trainning_spec/stage1.spec'.format(c['filename']),'w') as myfile:
		template = """[PATH]
config={path_config}
load={path_load}
data={path_data}
save={path_save}

[OPTIMIZE]
n_threads={threads}
force_fft=1
optimize_fft=0

[TRAIN]
test_range=1
outsz={output_path_size}
softmax=1

[MONITOR]
check_freq=10
test_freq=100

[SCAN]
outname={outname}"""

		context = {
					"path_config":'../znn/network_spec/VeryDeep2_w109.spec', 
					"path_load":'../znn/network_instance/VeryDeep2_w109/',
					"path_data":'../znn/data/{0}/data_spec/stage1.'.format(c['filename']),
					"path_save":'../znn/data/{0}/output/'.format(c['filename']),  #this is the path to outname
					"threads":threads,
					"output_path_size":'{0},{1},{2}'.format(outsz[2],outsz[1],outsz[0]), #x,y,z from z,y,x 
					"outname":'stage1'
		} 

		myfile.write(template.format(**context))

	#Return this stage output size
	return input_size - fov + numpy.array([1,1,1])

def stage2Train(c,input_size, fov):

	outsz = optimal_outsz(input_size , fov , architecture_multiplier= 1.5 * 10**5)


	with  open('../znn/data/{0}/trainning_spec/stage2.spec'.format(c['filename']),'w') as myfile:
		template = """[PATH]
config={path_config}
load={path_load}
data={path_data}
save={path_save}

[OPTIMIZE]
n_threads={threads}
force_fft=1
optimize_fft=0

[TRAIN]
test_range=1
outsz={output_path_size}
softmax=0

[MONITOR]
check_freq=10
test_freq=100

[SCAN]
outname={outname}"""

		context = {
					"path_config":'../znn/network_spec/VeryDeep2HR_w65x9.spec', 
					"path_load":'../znn/network_instance/VeryDeep2HR_w65x9/',
					"path_data":'../znn/data/{0}/data_spec/stage2.'.format(c['filename']),
					"path_save":'../znn/data/{0}/output/'.format(c['filename']),  #this is the path to outname
					"threads":threads,
					"output_path_size":'{0},{1},{2}'.format(outsz[2],outsz[1],outsz[0]), #x,y,z from z,y,x 
					"outname":'stage2'
		} 
		myfile.write(template.format(**context))

	#Return this stage output size
	return input_size - fov + numpy.array([1,1,1])


def save_input_size(c):

	with open('../znn/data/{0}/input/absolute_position.json'.format(c['filename']), 'wb') as fp:
		json.dump(c, fp)

	return

def save_output_size(c,fov):

	size =  {
			'x_min': c['x_min']+fov[2], 'x_max':c['x_max']-fov[2]
			,'y_min':c['y_min']+fov[1], 'y_max':c['y_max']-fov[1]
			,'z_min':c['z_min']+fov[1], 'z_max':c['z_max']-fov[0]
			,'filename':c['filename'] 
		}

	with open('../znn/data/{0}/output/absolute_position.json'.format(c['filename']), 'wb') as fp:
		json.dump(size, fp)

	return

def load_output_size(chunk_name):

	with open('../znn/data/{0}/output/absolute_position.json'.format(chunk_name), 'rb') as fp:
		return json.load(fp)
