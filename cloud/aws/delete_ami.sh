#!bin/sh
# chkconfig: 2345 96 14

us_region_name="us-east-1"
ami_id=""
temp_snapshot_id=""

my_array=( $(aws ec2 describe-images –image-ids $ami_id –region $us_region_name  –output text –query ‘Images[*].BlockDeviceMappings[*].Ebs.SnapshotId’) )

my_array_length=${#my_array[@]}

echo "Deregistering AMI: "$ami_id
aws ec2 deregister-image –image-id $ami_id –region $us_region_name

echo 'Removing Snapshot'

for (( i=0; i<$my_array_length; i++ ))
do
    temp_snapshot_id=${my_array[$i]}
    echo “Deleting Snapshot: “$temp_snapshot_id
    aws ec2 delete-snapshot –snapshot-id $temp_snapshot_id –region $us_region_name
done
