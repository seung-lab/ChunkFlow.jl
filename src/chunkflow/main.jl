import JSON
import DataStructures

fconfig = ARGS[1]

conf = readall(fconfig)
dc = JSON.parse(conf, dicttype=DataStructures.OrderedDict)

net = Tnet(dc)

forward(net)
