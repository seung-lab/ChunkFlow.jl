export default_params!, assert_params

function default_params!(pd)
    tmp_dir = pd["gn"]["tmp_dir"]
    if pd["gn"]["faffs"]==""
        pd["gn"]["faffs"] = "$(tmp_dir)/out_sample10_output_0.tif"
    end
end

function assert_params(pd)
end
