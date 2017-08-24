
"""
node function of watershed to produce atomic seg
"""
function nf_maskaffinity!( c::DictChannel,
                params::OrderedDict{Symbol, Any},
                inputs::OrderedDict{Symbol, Any},
                outputs::OrderedDict{Symbol, Any})
    chk_aff = fetch(c, inputs[:aff])
    chk_img = fetch(c, inputs[:img])

    @show size(chk_aff.data)
    # check it is an affinity map
    @assert isa(chk_aff.data, AffinityMap)
    @assert all( size(chk_aff)[1:3] == size(chk_img))

    if haskey(params, :sizeThreshold)
        mask = image2mask(  chk_img.data;
                            threshold=UInt8(params[:threshold]),
                            sizeThreshold=UInt32(params[:sizeThreshold]))
        maskaff!(mask, chk_aff.data)
    else
        maskaff!(chk_img.data, chk_aff.data)
    end

    put!(c, outputs[:aff], chk_aff)
end
