using EMIRT

"""
edge function of watershed to produce atomic seg
"""
function ef_maskaffinity!( c::DictChannel,
                params::OrderedDict{Symbol, Any},
                inputs::OrderedDict{Symbol, Any},
                outputs::OrderedDict{Symbol, Any})
    chk_aff = fetch(c, inputs[:aff])
    chk_img = fetch(c, inputs[:img])

    @show size(chk_aff.data)
    # check it is an affinity map
    @assert isa(chk_aff.data, AffinityMap)
    @assert all( size(chk_aff)[1:3] == size(chk_img))

    mask = image2mask(  chk_img.data;
                        threshold=UInt8(params[:threshold]),
                        sizeThreshold=UInt32(params[:sizeThreshold]))

    # mask the affinity
    for z in 2:size(mask, 3)
        for y in 1:size(mask, 2)
            for x in 1:size(mask, 1)
                if mask[x,y,z] || mask[x,y,z-1]
                    chk_aff.data[x,y,z] = 0.0f0
                end
            end
        end
    end

    for z in 1:size(mask, 3)
        for y in 2:size(mask, 2)
            for x in 1:size(mask, 1)
                if mask[x,y,z] || mask[x,y-1,z]
                    chk_aff.data[x,y,z] = 0.0f0
                end
            end
        end
    end

    for z in 1:size(mask, 3)
        for y in 1:size(mask, 2)
            for x in 2:size(mask, 1)
                if mask[x,y,z] || mask[x-1,y,z]
                    chk_aff.data[x,y,z] = 0.0f0
                end
            end
        end
    end

    put!(c, outputs[:aff], chk_aff)
end
