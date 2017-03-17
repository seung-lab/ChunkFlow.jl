module Operators

export AbstractChunkFlowOperator, get_read_variables, get_write_variables, run!

abstract AbstractChunkFlowOperator

function get_read_variables end
function get_write_variables end
function run! end

end # end of module
