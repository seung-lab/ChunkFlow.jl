include("../src/ChunkFlow.jl")
# using EMIRT
using DataStructures
using ChunkFlow
using ChunkFlow.Producer

# parse the arguments as a dictionary, key is string
global const argDict = parse_commandline()
@show argDict


# get origin set from a list of chunk files
#using BigArrays
#using BigArrays.H5sBigArrays
#baAff = H5sBigArray("~/seungmount/research/Jingpeng/14_zfish/affinitymap/");
#fileNames = keys(baAff)
#originSet = Producer.get_origin_set( fileNames )
originSet = OrderedSet{Vector}()

# produce tasks using the originSet
taskproducer( argDict; originSet = originSet )
