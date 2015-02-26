import math
import numpy
import json


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

def stage1Train(c,chunk_size,fov,nthreads,memory):

	#We want to make the output which is simulatenusly compute in znn (outz), proportionally to the field of view
	#So as much computation as possible is reuse, and we want to make it as large possible
	#Empirically we know the memory usage is proportinoal to outz, so we have to limit it size.
	scalar = math.pow(memory* 7000 / numpy.prod(fov), .33 )
	outz = (fov * scalar  - 1).astype(int)

	#Make sure the output is not larger that maximun, or less than 1
	maxOut = chunk_size - fov + numpy.array([1,1,1])
	outz[outz > maxOut] = maxOut[outz > maxOut]

	minOut = numpy.array([1,1,1])
	outz[outz < minOut] = minOut[outz < minOut]


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
					"threads":nthreads,
					"output_path_size":'{0},{1},{2}'.format(outz[2],outz[1],outz[0]), #x,y,z from z,y,x 
					"outname":'stage1'
		} 

		myfile.write(template.format(**context))

	#Return this stage output size
	return maxOut

def stage2Train(c,chunk_size,fov,nthreads,memory):

	#We want to make the output which is simulatenusly compute in znn (outz), proportionally to the field of view
	#So as much computation as possible is reuse, and we want to make it as large possible
	#Empirically we know the memory usage is proportinoal to outz, so we have to limit it size.
	scalar = math.pow(memory* 7000 / numpy.prod(fov), .33 )
	outz = (fov * scalar  - 1).astype(int)

	#Make sure the output is not larger that maximun, or less than 1
	maxOut = chunk_size - fov + numpy.array([1,1,1])
	outz[outz > maxOut] = maxOut[outz > maxOut]

	minOut = numpy.array([1,1,1])
	outz[outz < minOut] = minOut[outz < minOut]


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
					"threads":nthreads,
					"output_path_size":'{0},{1},{2}'.format(outz[2],outz[1],outz[0]), #x,y,z from z,y,x 
					"outname":'stage2'
		} 
		myfile.write(template.format(**context))

	#Return this stage output size
	return maxOut


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

def load_size(chunk_name):

	with open('data.json', 'rb') as fp:
		return json.load(fp)