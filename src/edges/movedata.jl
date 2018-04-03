# move data

"""
node function of movedata
"""
function nf_movedata(c::DictChannel,
                    params::OrderedDict{Symbol, Any},
                    inputs::OrderedDict{Symbol, Any},
                    outputs::OrderedDict{Symbol, Any} )
  # get chunk
  srcPrefix = replace(inputs[:prefix],  "~", homedir())
  dstDir    = replace(outputs[:dir],    "~", homedir())
  srcDir    = dirname(srcPrefix)

  # local movement of files
  for baseName in readdir(srcDir)
    if contains(baseName, basename(srcPrefix))
      dstFile = joinpath(dstDir, baseName)
      srcFile = joinpath(srcDir, baseName)
      if iss3(srcFile) || isGoogleStorage(srcFile)
        download(srcFile, dstFile)
      elseif iss3(dstFile) || isGoogleStorage(dstFile)
        upload(srcFile, dstFile)
        if params[:isRemoveSourceFile]
          rm(srcFile; recursive=true)
        end
      else
        if params[:isRemoveSourceFile]
          mv(joinpath(dirname(srcFile), baseName),
              joinpath(dirname(dstFile), baseName), remove_destination=true)
        else
          cp(joinpath(dirname(srcFile), baseName),
              joinpath(dirname(dstFile), baseName), remove_destination=true)
        end
      end
    end
  end
end
