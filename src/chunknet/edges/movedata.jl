# move data
# to-do: support uploading to S3
#include(joinpath(Pkg.dir(), "EMIRT/plugins/aws.jl"))

"""
edge function of movedata
"""
function ef_movedata(c::DictChannel,
                    params::OrderedDict{Symbol, Any},
                    inputs::OrderedDict{Symbol, Any},
                    outputs::OrderedDict{Symbol, Any} )
  # get chunk
  fin = replace(inputs[:prefix], "~", homedir())
  fot = replace(outputs[:dir], "~", homedir())
  if iss3(fin)
    download(awsEnv, fin, fot)
  elseif iss3(fot)
    upload(awsEnv, fin, fot)
    if params[:isRemoveSourceFile]
      rm(fin)
    end
  else
    # local movement of files
    for fbase in readdir(dirname(fin))
        if contains(fbase, basename(fin))
            fout = joinpath(fot, fbase)
            if params[:isRemoveSourceFile]
              mv(joinpath(dirname(fin), fbase),
                  joinpath(dirname(fot), fbase), remove_destination=true)
            else
              cp(joinpath(dirname(fin), fbase),
                  joinpath(dirname(fot), fbase), remove_destination=true)
            end
        end
    end
  end
end
