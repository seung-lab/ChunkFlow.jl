include(joinpath(dirname(@__FILE__), "../src/utils/ArgParsers.jl")
include(joinpath(dirname(@__FILE__), "../src/utils/Producers.jl")
using .ArgParsers
using .Producers
using DataStructures
using ChunkFlow

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

#using JLD
#originSet = OrderedSet( load("templates/zfish/originset.fix.2.jld", "originSet"))

# produce tasks using the originSet
taskproducer( argDict; originSet = originSet )
