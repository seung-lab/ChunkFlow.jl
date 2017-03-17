module Operators

export AbstractChunkFlowOperator
export get_read_variables, get_write_variables, run!

abstract AbstractChunkFlowOperator

function get_read_variables end
function get_write_variables end
function run! end

include("operators/agglomeration.jl")


end # end of module
