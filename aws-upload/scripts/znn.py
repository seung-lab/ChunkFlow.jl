import math
import numpy
import json

from global_vars import *

cache = dict()

def stage1Data(c):
	with  open('../data/{0}/data_spec/stage1.1.spec'.format(c['filename']),'w') as myfile:

		template = """[INPUT1]
path={path_input}
size={size}
pptype=standard2D"""

		context = {
			"path_input":'./data/{0}/input/input'.format(c['filename']), 
			"size": '{0},{1},{2}'.format(c['x_max']-c['x_min'],c['y_max']-c['y_min'],c['z_max']-c['z_min'])
		} 
		myfile.write(template.format(**context)) 

def stage2Data(c):
	with  open('../data/{0}/data_spec/stage2.1.spec'.format(c['filename']),'w') as myfile:

		template = """[INPUT1]
path={path_input}
size={size}
pptype=standard2D

[INPUT2]
path={path_output_stage1}.1
offset=54,54,0
pptype=transform
ppargs=-1,1"""

		context = {
			"path_input":'./data/{0}/input/input'.format(c['filename']), 
			"size": '{0},{1},{2}'.format(c['x_max']-c['x_min'],c['y_max']-c['y_min'],c['z_max']-c['z_min']),
			"path_output_stage1":'./data/{0}/output/stage11'.format(c['filename']),  #this is the path to outname
		} 
		myfile.write(template.format(**context)) 

def optimal_outsz(input_size, fov_in, max_memory = 200 * 10**9, architecture_multiplier= 5 * 10**5, div_precision = 50):
	#So based on the chunk size (`input_size`), and the fov of the current stage `fov_in`
	#we do a grid search from [1,1,1] to `chunk_size` which is the output size of the chunk 
	#and it choose the best_outz based on the metric `score`
	
	#implement a cache because this takes long to run
	args = {'input_size':input_size.tostring(), 'fov_in':fov_in.tostring(), 'max_memory':max_memory, 'architecture_multiplier':architecture_multiplier , 'div_precision':div_precision}
	args = frozenset(args.items())
	if args in cache:
		print 'from cache' , cache[args]
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
				memory = numpy.prod(outsz + fov - 1) * architecture_multiplier
				if memory > max_memory:
					continue

				computation_done = numpy.prod(numpy.ceil(chunk_size/outsz) * (outsz + fov - 1))

				if computation_done < min_score:
					min_score = computation_done
					best_outsz = outsz

	print best_outsz
	cache[args] = best_outsz
	return best_outsz


def stage1Train(c,input_size,fov):

	outsz = optimal_outsz(input_size , fov, architecture_multiplier= 2.4 * 10**5)

	with  open('../data/{0}/trainning_spec/stage1.spec'.format(c['filename']),'w') as myfile:
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
					"path_config":'./network_spec/VeryDeep2_w109.spec', 
					"path_load":'./network_instance/VeryDeep2_w109/',
					"path_data":'./data/{0}/data_spec/stage1.'.format(c['filename']),
					"path_save":'./data/{0}/output/'.format(c['filename']),  #this is the path to outname
					"threads":threads,
					"output_path_size":'{0},{1},{2}'.format(outsz[2],outsz[1],outsz[0]), #x,y,z from z,y,x 
					"outname":'stage1'
		} 

		myfile.write(template.format(**context))

	#Return this stage output size
	return input_size - fov + numpy.array([1,1,1])

def stage2Train(c,input_size, fov):

	outsz = optimal_outsz(input_size , fov , architecture_multiplier= 1.5 * 10**5)


	with  open('../data/{0}/trainning_spec/stage2.spec'.format(c['filename']),'w') as myfile:
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
					"path_config":'./network_spec/VeryDeep2HR_w65x9.spec', 
					"path_load":'./network_instance/VeryDeep2HR_w65x9/',
					"path_data":'./data/{0}/data_spec/stage2.'.format(c['filename']),
					"path_save":'./data/{0}/output/'.format(c['filename']),  #this is the path to outname
					"threads":threads,
					"output_path_size":'{0},{1},{2}'.format(outsz[2],outsz[1],outsz[0]), #x,y,z from z,y,x 
					"outname":'stage2'
		} 
		myfile.write(template.format(**context))

	#Return this stage output size
	return input_size - fov + numpy.array([1,1,1])


def save_input_size(c):

	with open('../data/{0}/input/absolute_position.json'.format(c['filename']), 'wb') as fp:
		json.dump(c, fp)

	return

def save_output_size(c,fov):

	size =  {
			'x_min': c['x_min']+fov[2], 'x_max':c['x_max']-fov[2]
			,'y_min':c['y_min']+fov[1], 'y_max':c['y_max']-fov[1]
			,'z_min':c['z_min']+fov[1], 'z_max':c['z_max']-fov[0]
			,'filename':c['filename'] 
		}

	with open('../data/{0}/output/absolute_position.json'.format(c['filename']), 'wb') as fp:
		json.dump(size, fp)

	return

def load_output_size(chunk_name):

	with open('../data/{0}/output/absolute_position.json'.format(chunk_name), 'rb') as fp:
		return json.load(fp)
