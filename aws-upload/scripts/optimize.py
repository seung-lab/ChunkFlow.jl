import numpy


#Constrains
max_nodes = 2 

stack = numpy.array([600.0, 600.0 , 167.0])

fov_1 = numpy.array([109.0,109.0,1.0])

fov_2 = numpy.array([65.0,65.0,9.0])
fov_effective = fov_1 + fov_2 -2 
speed = 7500


min_timeRequired = numpy.float('inf')
for x in range(1,max_nodes):
	for y in range(1,max_nodes):
		for z in range(1,max_nodes):
			
			if x*y*z > max_nodes:
				continue

			divs = numpy.array([x,y,z])
			timeRequired = numpy.prod( (stack+fov_effective*(divs-1)) / divs)
			if timeRequired < min_timeRequired:
				min_timeRequired = timeRequired
				best_divs = divs

print best_divs

chunk_size = (stack - fov_effective) / best_divs + fov_effective

outsz_1 = fov_1
outsz_2 = fov_2

max_score = 0
for x in range(1,chunk_size[0].astype(int),10):
	for y in range(1,chunk_size[1].astype(int),10):
		for z in range(1,chunk_size[2].astype(int),10):
			outsz_1 = numpy.array([x,y,z])

			efficiency_subvolume_1 = chunk_size / (numpy.ceil(chunk_size/outsz_1) * (outsz_1 + fov_1 - 1))
			efficiency_outsz_1 = outsz_1 / (outsz_1 + fov_1 -1)
			score = numpy.prod(efficiency_subvolume_1) * numpy.prod(efficiency_outsz_1) * numpy.prod(outsz_1)


			if score > max_score:
				max_score = score
				best_outsz_1 = outsz_1

print chunk_size
print best_outsz_1

# efficiency_subvolume_2 = chunk_size / (numpy.ceil(chunk_size/outsz_2) * (outsz_2 + fov_2 - 1))
# efficiency_outsz_2 = outsz_2 / (outsz_2 + fov_2 -1)
# numpy.prod(efficiency_subvolume_2) * numpy.prod(efficiency_outsz_2) 