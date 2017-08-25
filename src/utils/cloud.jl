module Cloud

using AWSS3

export download, upload

"""
whether this file is in s3
"""
function iss3(fname)
    return ismatch(r"^(s3://)", fname)
end

"""
whether this file is google storage
"""
function isgs(fname)
  return ismatch(r"^(gs://)", fname)
end

"""
split a s3 path to bucket name and key
"""
function splits3(path::AbstractString)
    path = replace(path, "s3://", "")
    bkt, key = split(path, "/", limit = 2)
    return String(bkt), String(key)
end

"""
download file from AWS S3
"""
function downloads3(remoteFile::AbstractString, localFile::AbstractString)
  # get bucket name and key
  bkt,key = splits3(remoteFile)
  # download s3 file using awscli
  f = open(localFile, "w")
  obj = s3_get(bkt, key)
  write( f, obj )
  close(f)
  return localFile
end

"""
transfer s3 file to local and return local file name
`Inputs:`
remoteFile: String, s3 file path
localFile: String, local temporal folder path or local file name

`Outputs:`
localFile: String, local file name
"""
function Base.download(remoteFile::AbstractString, localFile::AbstractString)
    # directly return if not s3 file
    @assert iss3(remoteFile) || isgs(remoteFile)

    if isdir(localFile)
        localFile = joinpath(localFile, basename(remoteFile))
    end
    # remove existing file
    if isfile(localFile)
        rm(localFile)
    elseif !isdir(dirname(localFile))
        # create nested local directory
        @show localFile
        mkpath(dirname(localFile))
    end

    if iss3(remoteFile)
        #downloads3(remoteFile, localFile)
        run(`aws s3 cp $(remoteFile) $(localFile)`)
    elseif isgs(remoteFile)
        run(`gsutil -m cp $remoteFile $localFile`)
    end
    return localFile
end

function upload(localFile::AbstractString, remoteFile::AbstractString)
    if iss3(remoteFile)
        # relies on awscli because the upload of AWS.S3 is not really working!
        # https://github.com/JuliaCloud/AWS.jl/issues/70
        if isdir(localFile)
            run(`aws s3 cp --recursive $(localFile) $(remoteFile)`)
            #run(`aws s3 sync $(localFile) $(remoteFile)`)
        else
            @assert isfile(localFile)
            run(`aws s3 cp $(localFile) $(remoteFile)`)
        end
    elseif isgs(remoteFile)
        if isdir(localFile)
            # run(`gsutil -m cp -r $localFile $remoteFile`)
            run(`gsutil -m rsync -r $localFile $remoteFile`)
        else
            @assert isfile(localFile)
            run(`gsutil -m cp $localFile $remoteFile`)
        end
    else
        error("unsupported remote file link: $(remoteFile)")
    end
end

end # end of module
