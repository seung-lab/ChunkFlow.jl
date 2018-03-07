using AWSSDK.Batch
using ArgParse
using AWSCore

const AWS_CREDENTIAL = AWSCore.config()
const ARG_DICT = parse_commandline()

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--command", "-e"
            help = "command to run"
            arg_type = String 
        "--image", "-i"
            help = "docker image"
            arg_type = String 
            default = "jingpengw/chunkflow.jl:inference-script"
        "--memory", "-m"
            help = "required memory size in GB"
            arg_type = Int 
            default = 8
        "--cores", "-c"
            help = "number of cores"
            arg_type = Int 
            default = 4
        "--instance-type", "-t"
            help = "instance type"
            arg_type = String
            default = "c5.xlarge"
        "--job-number", "-n"
            help = "job number"
            arg_type = Int 
            default = 1 
        "--job-name", ""
    end
    return parse_args(s)
end


function main()
    @sync begin 
        for _ in 1:ARG_DICT["job-number"]
            @async Batch.submit_job(AWS_CREDENTIAL; 
                            jobName = "")
        end
    end 
end 

main()
