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





def getOutSize(input_size , fov,  memory , stage):

	if stage == 1:
	 	architecture_multiplyer = 0.6 * 10**5
	else:
	 	architecture_multiplyer = 0.6 * 10**5

	#Given the input size and the field of view, we compute the output size
	output_size = input_size - fov + numpy.array([1,1,1])

	#We want to have a subvolume, which is a divisor of the output_size , and has shape which is similar
	#to the shape of the field of view
	#and uses an ammount of memory closer to the maximun memory
	best_score = 0
	best_conf = None
	for z in list(divisorGenerator(output_size[0])):
		for y in list(divisorGenerator(output_size[1])):
			for x in list(divisorGenerator(output_size[2])):
				conf = numpy.array([z, y, x])
				#Check memory usage for this configuration
				memory_used = numpy.prod(conf + fov - numpy.array([1,1,1])) * architecture_multiplyer

				#Lets threat this configuration and the fov as vectors, and check how alignn both are.
				#We want the configuration to have a similar shape to FoV
				fov_versor = fov/numpy.linalg.norm(fov)
				conf_versor = conf/numpy.linalg.norm(conf)
				fov_score = numpy.prod( (conf/fov.astype(float))**2) 

				if memory_used < memory and fov_score * memory_used > best_score:
					best_conf = conf
	
	print 'output_size', output_size ,' fov ', fov , ' outz' , best_conf
	return best_conf


def stage1Train(c,input_size,fov, nthreads,memory):

	outz = getOutSize(input_size , fov,  memory , 1 )

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
	return input_size - fov + numpy.array([1,1,1])

def stage2Train(c,input_size,fov,nthreads, memory):

	outz = getOutSize(input_size , fov,  memory , 2 )


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

def load_size(chunk_name):

	with open('data.json', 'rb') as fp:
		return json.load(fp)


def divisorGenerator(n):

	n = int(n)
	large_divisors = []
	for i in xrange(1, int(math.sqrt(n) + 1)):
		if n % i is 0:
			yield i
			if i is not n / i:
				large_divisors.insert(0, n / i)
	for divisor in large_divisors:
		yield divisor

