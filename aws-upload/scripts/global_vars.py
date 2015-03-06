import numpy

#number of nodes available
max_nodes = 4

#Set the resources for the machine in which znn ,watershed and omnify will be run
memory = 200 * 10**9#gb
threads = 32

# We will apply two neural networks (stage1 and stage2)
# We need to know the field of view of each stage, and the "effective" field of view
# i.e. the FoV combined of both stages
fov_stage1 = numpy.array([1,109,109])
fov_stage2 = numpy.array([9,65,65])
fov_effective = numpy.array([9,173,173])