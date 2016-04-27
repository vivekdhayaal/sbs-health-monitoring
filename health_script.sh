checkStatus() {
#####This function is used to check state of a volume/instance/snapshot
###Usage
#checkStatus volume/instance/snapshot <volumeId/instanceId/snapshotId> <available/in-use/running/completed>	
	count=0
	status=""
	sleep 20

	###Check if state is running
	while (($count != 20)); do

	if (($1 == 0))
	then
	result=`eval "$(./create_request.py "https://compute.ind-west-1.internal.jiocloudservices.com/?Action=DescribeVolumes&Version=2016-03-01&VolumeId=$2")"`
	status=`echo $result|sed -n -e 's/.*<status>\(.*\)<\/status>.*/\1/p'`
       	echo -e "Describe volume for $2." >> $4  
	else
	if (($1 == 1))
	then
	result=`eval "$(./create_request.py "https://compute.ind-west-1.internal.jiocloudservices.com/?Action=DescribeInstances&Version=2016-03-01&InstanceId.1=$2")"`
	status=`echo $result|sed -n -e 's/.*<instanceState>\(.*\)<\/instanceState>.*/\1/p'`
       	echo -e "Describe instance for $2." >> $4   
	else
	result=`eval "$(./create_request.py "https://compute.ind-west-1.internal.jiocloudservices.com/?Action=DescribeSnapshots&Version=2016-03-01&SnapshotId=$2")"`
	status=`echo $result|sed -n -e 's/.*<status>\(.*\)<\/status>.*/\1/p'`
       	echo -e "Describe snapshot for $2." >> $4
	fi
	fi
	
	if [  -z "$status" ];
	then
        	echo -e "Describe $2 failed.\n`date` Output is $result" >> $4
	fi

	create=1
	if [ "$status" = "$3" ];
	then
		create=0
		count=20
	else
		sleep 1
	        count=$((count+1))
	fi
	done

	echo -e "status: $status" >>$4
	echo "### $2 status: $status ###"
	if (($create!= 0))
	then
        	echo -e "Check $2 failed\n`date` Output is $result" >>$4
	fi

	return $create
}

inst_status='running'

###-----------------------------------------------------------------------------
#Create an instance
###-----------------------------------------------------------------------------
echo -e "\n*********Create Instance *********" >>$1
result=`eval "$(./create_request.py "https://compute.ind-west-1.internal.jiocloudservices.com/?Action=RunInstances&ImageId=jmi-74710812&KeyName=test_key&InstanceTypeId=c1.medium&BlockDeviceMapping.1.DeleteOnTermination=True&BlockDeviceMapping.1.DeviceName=/dev/vda&Version=2016-03-01")"`
inst_id=`echo $result|sed -n -e 's/.*<instanceId>\(.*\)<\/instanceId>.*/\1/p'`
if [  -z "$inst_id" ];
then
        echo -e "Create instance failed.\n`date` Output is $result" >>$1
	exit 1
fi

echo "Created instance $inst_id">> $1

###-----------------------------------------------------------------------------
# check instance status using DescribeInstances
###-----------------------------------------------------------------------------
checkStatus 1 $inst_id running $1 
ret=$?
if (($ret!= 0))
then 
        echo -e "Describe instance failed for running state at `date`" >>$1
	exit 1
fi
###-----------------------------------------------------------------------------
# create Volume 
###-----------------------------------------------------------------------------
echo -e "\n*********Create Volume *********" >>$1
result=`eval "$(./create_request.py "https://compute.ind-west-1.internal.jiocloudservices.com/?Action=CreateVolume&Size=1&Version=2016-03-01")"`
vol_id=`echo $result|sed -n -e 's/.*<volumeId>\(.*\)<\/volumeId>.*/\1/p'`
if [  -z "$vol_id" ];
then
        echo -e "Create volume failed.\n`date` Output is $result" >>$1
	exit 1
fi

echo "Created volume $vol_id">>$1

###-----------------------------------------------------------------------------
# describe Volume 
###-----------------------------------------------------------------------------
checkStatus 0 $vol_id available $1 
ret=$?
if (($ret!= 0))
then 
        echo -e "Describe volume failed for available state at `date`" >>$1
	exit 1
fi

###-----------------------------------------------------------------------------
#Attach volume to instance
###-----------------------------------------------------------------------------
echo -e "\n*********Attach Volume for volume $vol_id and instance $inst_id*********" >>$1
result=`eval "$(./create_request.py "https://compute.ind-west-1.internal.jiocloudservices.com/?Action=AttachVolume&InstanceId=$inst_id&VolumeId=$vol_id&Device=/dev/vdb&Version=2016-03-01")"`
status=`echo $result|sed -n -e 's/.*<status>\(.*\)<\/status>.*/\1/p'`
if [  -z "$status" ];
then
        echo -e "Attach volume failed.\n`date` Output is $result" >>$1
	exit 1
fi
echo "Attached volume $vol_id to instance $inst_id">>$1
###-----------------------------------------------------------------------------
# describe Volume 
###-----------------------------------------------------------------------------
checkStatus 0 $vol_id in-use $1 
ret=$?
if (($ret!= 0))
then 
        echo -e "Describe volume failed for in-use state at `date`" >>$1
	exit 1
fi

###-----------------------------------------------------------------------------
# CreateSnapshot S1 
###-----------------------------------------------------------------------------
echo -e "\n*********Create snapshot for volume $vol_id*********" >>$1
result=`eval "$(./create_request.py "https://compute.ind-west-1.internal.jiocloudservices.com/?Action=CreateSnapshot&VolumeId=$vol_id&Version=2016-03-01")"`
base_snap_id=`echo $result|sed -n -e 's/.*<snapshotId>\(.*\)<\/snapshotId>.*/\1/p'`
if [  -z "$base_snap_id" ];
then
        echo -e "Create snapshot failed.\n`date` Output is $result" >>$1
	exit 1
fi
echo -e "Created snapshot $base_snap_id for volume $vol_id" >>$1
###-----------------------------------------------------------------------------
# describe snapshot 
###-----------------------------------------------------------------------------
checkStatus 2 $base_snap_id completed $1 
ret=$?
if (($ret!= 0))
then 
        echo -e "Create snapshot failed for completed state at `date`" >>$1
	exit 1
fi
###-----------------------------------------------------------------------------
# CreateSnapshot S2 
###-----------------------------------------------------------------------------
echo -e "\n*********Create snapshot for volume $vol_id********* " >>$1
result=`eval "$(./create_request.py "https://compute.ind-west-1.internal.jiocloudservices.com/?Action=CreateSnapshot&VolumeId=$vol_id&Version=2016-03-01")"`
snap_id=`echo $result|sed -n -e 's/.*<snapshotId>\(.*\)<\/snapshotId>.*/\1/p'`
if [  -z "$snap_id" ];
then
        echo -e "Create snapshot failed.\n`date` Output is $result" >>$1
	exit 1
fi
echo -e "Created snapshot $snap_id for volume $vol_id" >>$1
###-----------------------------------------------------------------------------
# describe snapshot 
###-----------------------------------------------------------------------------
checkStatus 2 $snap_id completed $1 
ret=$?
if (($ret!= 0))
then 
        echo -e "Create snapshot failed for completed state at `date`" >>$1
	exit 1
fi
###-----------------------------------------------------------------------------
# detach Volume 
###-----------------------------------------------------------------------------
echo -e "\n*********Detach volume $vol_id*********" >>$1
result=`eval "$(./create_request.py "https://compute.ind-west-1.internal.jiocloudservices.com/?Action=DetachVolume&InstanceId=$inst_id&VolumeId=$vol_id&Device=/dev/vdb&Version=2016-03-01")"`
status=`echo $result|sed -n -e 's/.*<status>\(.*\)<\/status>.*/\1/p'`
if [  -z "$status" ];
then
        echo -e "Detach volume $vol_id failed.\n`date` Output is $result" >>$1
	exit 1
fi
echo "Detached volume $vol_id" >> $1
###-----------------------------------------------------------------------------
# describe volume 
###-----------------------------------------------------------------------------
checkStatus 0 $vol_id available $1 
ret=$?
if (($ret!= 0))
then 
        echo -e "Describe volume failed for available state at `date`" >>$1
	exit 1
fi
###-----------------------------------------------------------------------------
# delete volume
###-----------------------------------------------------------------------------
echo -e "\n*********Delete volume $vol_id*********" >>$1
result=`eval "$(./create_request.py "https://compute.ind-west-1.internal.jiocloudservices.com/?Action=DeleteVolume&VolumeId=$vol_id&Version=2016-03-01")"`
status=`echo $result|sed -n -e 's/.*<return>\(.*\)<\/return>.*/\1/p'`
if [  -z "$status" ];
then
        echo -e "Delete Volume $vol_id failed.\n`date` Output is $result" >>$1
	exit 1
fi
echo "Deleted volume $vol_id" >> $1

###-----------------------------------------------------------------------------
# describe volume
###-----------------------------------------------------------------------------
sleep 30
result=`eval "$(./create_request.py "https://compute.ind-west-1.internal.jiocloudservices.com/?Action=DescribeVolumes&VolumeId=$vol_id&Version=2016-03-01")"`
status=`echo $result|sed -n -e 's/.*<Code>\(.*\)<\/Code>.*/\1/p'`
if [  -z "$status" ];
then
        echo -e "Describe Volume $vol_id failed.\n`date` Output is $result" >>$1
	exit 1
fi
if [ "InvalidVolume.NotFound" != $status ]
then
        echo -e "Describe Volume $vol_id still exists\n`date` Output is $result" >>$1
	exit 1
fi
###-----------------------------------------------------------------------------
# create volume from snapshot
###-----------------------------------------------------------------------------
echo -e "\n*********Create volume from snapshot *********" >>$1
result=`eval "$(./create_request.py "https://compute.ind-west-1.internal.jiocloudservices.com/?Action=CreateVolume&SnapshotId=$snap_id&Version=2016-03-01")"`
vol_id=`echo $result|sed -n -e 's/.*<volumeId>\(.*\)<\/volumeId>.*/\1/p'`
if [  -z "$vol_id" ];
then
        echo -e "Create volume from snapshot failed $result" >>$1
	exit 1
fi
echo "Created volume $vol_id" >> $1
###-----------------------------------------------------------------------------
# describe Volume 
###-----------------------------------------------------------------------------
checkStatus 0 $vol_id available $1 
ret=$?
if (($ret!= 0))
then 
        echo -e "Describe volume failed for available state at `date`" >>$1
	exit 1
fi
###-----------------------------------------------------------------------------
#Attach volume to instance
###-----------------------------------------------------------------------------
echo -e "\n*********Attach volume $vol_id to instance $inst_id*********" >>$1
result=`eval "$(./create_request.py "https://compute.ind-west-1.internal.jiocloudservices.com/?Action=AttachVolume&InstanceId=$inst_id&VolumeId=$vol_id&Device=/dev/vdb&Version=2016-03-01")"`
status=`echo $result|sed -n -e 's/.*<status>\(.*\)<\/status>.*/\1/p'`
if [  -z "$status" ];
then
        echo -e "Attach volume failed.\n`date` Output is $result" >>$1
	exit 1
fi
echo -e "Attached volume $vol_id to instance $inst_id" >>$1
###-----------------------------------------------------------------------------
# describe Volume 
###-----------------------------------------------------------------------------
checkStatus 0 $vol_id in-use $1 
ret=$?
if (($ret!= 0))
then 
        echo -e "Describe volume failed for in-use state at `date`" >>$1
	exit 1
fi
###-----------------------------------------------------------------------------
# detach Volume 
###-----------------------------------------------------------------------------
echo -e "\n*********Detach volume $vol_id from instance $inst_id*********" >>$1
result=`eval "$(./create_request.py "https://compute.ind-west-1.internal.jiocloudservices.com/?Action=DetachVolume&InstanceId=$inst_id&VolumeId=$vol_id&Device=/dev/vdb&Version=2016-03-01")"`
status=`echo $result|sed -n -e 's/.*<status>\(.*\)<\/status>.*/\1/p'`
if [  -z "$status" ];
then
        echo -e "Detach Volume $vol_id failed.\n`date` Output is $result" >>$1
	exit 1
fi
###-----------------------------------------------------------------------------
# describe volume 
###-----------------------------------------------------------------------------
checkStatus 0 $vol_id available $1 
ret=$?
if (($ret!= 0))
then 
        echo -e "Describe volume failed for available state at `date`" >>$1
	exit 1
fi
echo -e "Detached volume $vol_id" >>$1
###-----------------------------------------------------------------------------
# delete volume
###-----------------------------------------------------------------------------
echo -e "\n*********Delete volume $vol_id*********" >>$1
result=`eval "$(./create_request.py "https://compute.ind-west-1.internal.jiocloudservices.com/?Action=DeleteVolume&VolumeId=$vol_id&Version=2016-03-01")"`
status=`echo $result|sed -n -e 's/.*<return>\(.*\)<\/return>.*/\1/p'`
if [  -z "$status" ];
then
        echo -e "Delete Volume $vol_id failed.\n`date` Output is $result" >>$1
	exit 1
fi
if [ "true" != $status ]
then
        echo -e "Delete Volume $vol_id still exists\n`date` Output is $result" >>$1
	exit 1
fi

###-----------------------------------------------------------------------------
# describe volume
###-----------------------------------------------------------------------------
sleep 30
result=`eval "$(./create_request.py "https://compute.ind-west-1.internal.jiocloudservices.com/?Action=DescribeVolumes&VolumeId=$vol_id&Version=2016-03-01")"`
status=`echo $result|sed -n -e 's/.*<Code>\(.*\)<\/Code>.*/\1/p'`
if [  -z "$status" ];
then
        echo -e "Describe Volume $vol_id failed.\n`date` Output is $result" >>$1
	exit 1
fi
if [ "InvalidVolume.NotFound" != $status ]
then
        echo -e "Describe Volume $vol_id still exists\n`date` Output is $result" >>$1
fi
echo -e "Deleted volume $vol_id">>$1
###-----------------------------------------------------------------------------
# DeleteSnapshot base snapshot 
###-----------------------------------------------------------------------------
echo -e "\n*********Delete snapshot $base_snap_id*********" >>$1
result=`eval "$(./create_request.py "https://compute.ind-west-1.internal.jiocloudservices.com/?Action=DeleteSnapshot&SnapshotId=$base_snap_id&Version=2016-03-01")"`
status=`echo $result|sed -n -e 's/.*<return>\(.*\)<\/return>.*/\1/p'`
if [  -z "$status" ];
then
        echo -e "Delete snapshot failed.\n`date` Output is $result" >>$1
	exit 1
fi
if [ "true" != $status ]
then
        echo -e "Delete Snapshot $base_snap_id still exists\n`date` Output is $result" >>$1
	exit 1
fi
###-----------------------------------------------------------------------------
# describe snapshot 
###-----------------------------------------------------------------------------
sleep 60
result=`eval "$(./create_request.py "https://compute.ind-west-1.internal.jiocloudservices.com/?Action=DescribeSnapshots&SnapshotId=$base_snap_id&Version=2016-03-01")"`
status=`echo $result|sed -n -e 's/.*<Code>\(.*\)<\/Code>.*/\1/p'`
if [  -z "$status" ];
then
        echo -e "Describe Snapshot $base_snap_id failed.\n`date` Output is $result" >>$1
	exit 1
fi
if [ "InvalidSnapshot.NotFound" != $status ]
then
        echo -e "Describe Snapshot $base_snap_id still exists\n`date` Output is $result" >>$1
	exit 1
fi
echo -e "Deleted snapshot $base_snap_id " >>$1
###-----------------------------------------------------------------------------
# DeleteSnapshot S1 
###-----------------------------------------------------------------------------
echo -e "\n*********Delete snapshot $snap_id*********" >>$1
result=`eval "$(./create_request.py "https://compute.ind-west-1.internal.jiocloudservices.com/?Action=DeleteSnapshot&SnapshotId=$snap_id&Version=2016-03-01")"`
status=`echo $result|sed -n -e 's/.*<return>\(.*\)<\/return>.*/\1/p'`
if [  -z "$status" ];
then
        echo -e "Delete snapshot failed.\n`date` Output is $result" >>$1
	exit 1
fi
if [ "true" != $status ]
then
        echo -e "Delete Snapshot $snap_id still exists\n`date` Output is $result" >>$1
	exit 1
fi
###-----------------------------------------------------------------------------
# describe snapshot 
###-----------------------------------------------------------------------------
sleep 60
result=`eval "$(./create_request.py "https://compute.ind-west-1.internal.jiocloudservices.com/?Action=DescribeSnapshots&SnapshotId=$snap_id&Version=2016-03-01")"`
status=`echo $result|sed -n -e 's/.*<Code>\(.*\)<\/Code>.*/\1/p'`
if [  -z "$status" ];
then
        echo -e "Describe Snapshot $snap_id failed.\n`date` Output is $result" >>$1
	exit 1
fi
if [ "InvalidSnapshot.NotFound" != $status ]
then
        echo -e "Describe Snapshot $snap_id still exists\n`date` Output is $result" >>$1
	exit 1
fi
echo -e "Deleted snapshot $snap_id " >>$1
###-----------------------------------------------------------------------------
# DeleteInstance 
###-----------------------------------------------------------------------------
echo -e "\n*********Delete instance $inst_id*********" >>$1
result=`eval "$(./create_request.py "https://compute.ind-west-1.internal.jiocloudservices.com/?Action=TerminateInstances&InstanceId.1=$inst_id&Version=2016-03-01")"`
status=`echo $result|sed -n -e 's/.*<currentState>\(.*\)<\/currentState>.*/\1/p'`
if [  -z "$status" ];
then
        echo -e "Terminate instance $inst_id failed.\n`date` Output is $result" >>$1
	exit 1
fi
if [ "shutting-down" != $status ]
then
        echo -e "Instance $inst_id still exists\n`date` Output is $result" >>$1
	exit 1
fi
echo "Shutting down instance $inst_id" >> $1
###-----------------------------------------------------------------------------
# describe  
###-----------------------------------------------------------------------------
sleep 30
result=`eval "$(./create_request.py "https://compute.ind-west-1.internal.jiocloudservices.com/?Action=DescribeInstances&InstanceId.1=$inst_id&Version=2016-03-01")"`
status=`echo $result|sed -n -e 's/.*<Code>\(.*\)<\/Code>.*/\1/p'`
if [  -z "$status" ];
then
        echo -e "Describe instances $inst_id failed.\n`date` Output is $result" >>$1
	exit 1
fi
if [ "InvalidInstanceID.NotFound" != $status ]
then
        echo -e "Describe Instances $inst_id still exists\n`date` Output is $result" >>$1
fi
echo "Terminated instance $inst_id" >> $1
