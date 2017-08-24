
function nf_sleep( c::DictChannel,
                params::OrderedDict{Symbol,Any},
                inputs::OrderedDict{Symbol,Any},
                outputs::OrderedDict{Symbol,Any})
    println("sleep for $(params[:time]) seconds...")
    sleep(params[:time])
end
