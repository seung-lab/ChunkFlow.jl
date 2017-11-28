include("ArgParsers.jl"); using .ArgParsers 
using AWSSQS

global const argDict = parse_commandline()
@show argDict

queue = AWSSQS.sqs_get_queue( argDict[:queuename] )

startList = Vector{Tuple}()
for z in 1:argDict[:gridsize][3]
    for y in 1:argDict[:gridsize][2]
        for x in 1:argDict[:gridsize][1]
            grid = (x,y,z)
            start = map((g,o,s) ->o+(g-1)*s, grid, argDict[:origin], argDict[:stride])
            push!(startList, (start...))
        end 
    end 
end 

println("get $(length(startList)) starting points.")

if argDict[:isshuffle]
    shuffle!(startList)
end 

for i in 1:10:length(startList)
    println("submitting start id: $(i) --> $(i+9)")
    messageList = map(x -> "$(x[1]),$(x[2]),$(x[3])", 
                            startList[i:min(i+9, length(startList))])
    sqs_send_message_batch(queue, messageList)
end 
