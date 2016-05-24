
source sbs_variables.sh
#####checkStatus function is used to check state of a volume/instance/snapshot
###Usage
#checkStatus volume(0)/instance(1)/snapshot(2) <volumeId/instanceId/snapshotId> <available/in-use/running/completed>	
#eg "checkStatus 0 $vol_id available" if we want to check available status of a volume
#eg "checkStatus 1 $inst_id running" if we want to check running status of a instance
#eg "checkStatus 2 $snap_id completed" if we want to check completed status of a snapshot
checkStatus() {
	count=0
	status=""
	sleep 10


	###Check that state is reached until 20 times
	while (($count != 20)); do
	
	    if (($1 == 0))
	    then
	        result=`eval "$(./create_request.py "$compute_endpoint/?Action=DescribeVolumes&Version=$version&VolumeId=$2")"`
		if [ $3 = "invalid" ]
		then
	            status=`echo $result|sed -n -e 's/.*<Code>\(.*\)<\/Code>.*/\1/p'`
		else
  	            status=`echo $result|sed -n -e 's/.*<status>\(.*\)<\/status>.*/\1/p'`
		fi
                echo -e "Describe volume for $2." >> $4  
	    else
	    if (($1 == 1))
	    then
	        result=`eval "$(./create_request.py "$compute_endpoint/?Action=DescribeInstances&Version=$version&InstanceId.1=$2")"`
		if [ $3 = "invalid" ]
		then
	            status=`echo $result|sed -n -e 's/.*<Code>\(.*\)<\/Code>.*/\1/p'`
		else
	            status=`echo $result|sed -n -e 's/.*<instanceState>\(.*\)<\/instanceState>.*/\1/p'`
		fi
                echo -e "Describe instance for $2." >> $4   
	    else
	        result=`eval "$(./create_request.py "$compute_endpoint/?Action=DescribeSnapshots&Version=$version&SnapshotId=$2")"`
		if [ $3 = "invalid" ]
		then
	            status=`echo $result|sed -n -e 's/.*<Code>\(.*\)<\/Code>.*/\1/p'`
		else
	            status=`echo $result|sed -n -e 's/.*<status>\(.*\)<\/status>.*/\1/p'`
		fi
                echo -e "Describe snapshot for $2." >> $4
	    fi
	    fi
	
    	    if [  -z "$status" ];
	    then
            	echo -e "Describe $2 failed.\n`date` Output is $result" >> $4
	    fi

	    create=1
	    if [ $status = $3 ]
	    then
	    	create=0
	    	count=20
	    else
		if [[ $status == Invalid*NotFound ]]
	    	then
	    	  create=0
	    	  count=20
	    	else
        	  echo -e "\n******waiting 20 sec to check status*********" >>$4
	    	  sleep 20
	          count=$((count+1))
	        fi
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

createVolume() {
#####This function is used to create volume
###Usage
#checkStatus logFile volume-size <vol_id>
# return value in <vol_id>
	echo -e "\n*********Create Volume *********" >>$1
	result=`eval "$(./create_request.py "$compute_endpoint/?Action=CreateVolume&Size=$2&Version=$version")"`
	vol=`echo $result|sed -n -e 's/.*<volumeId>\(.*\)<\/volumeId>.*/\1/p'`
	if [  -z "$vol" ];
	then
	        echo -e "Create volume failed.\n`date` Output is $result" >>$1
		exit 1
	fi
	
	echo "Created volume $vol">>$1
	
	###-----------------------------------------------------------------------------
	# describe Volume 
	###-----------------------------------------------------------------------------
	checkStatus 0 $vol available $1 
	ret=$?
	if (($ret!= 0))
	then 
	        echo -e "Describe volume failed for available state at `date`" >>$1
		exit 1
	fi
        eval  "$3='$vol'"
}
createSnapshot() {
#####This function is used to create snapshot
###Usage
#createSnapshot logFile vol_id <snap_id>
# return value in <snap_id>
	###-----------------------------------------------------------------------------
	# CreateSnapshot S2 
	###-----------------------------------------------------------------------------
	echo -e "\n*********Create snapshot for volume $2********* " >>$1
	result=`eval "$(./create_request.py "$compute_endpoint/?Action=CreateSnapshot&VolumeId=$2&Version=$version")"`
	snap_id=`echo $result|sed -n -e 's/.*<snapshotId>\(.*\)<\/snapshotId>.*/\1/p'`
	if [  -z "$snap_id" ];
	then
	        echo -e "Create snapshot failed.\n`date` Output is $result" >>$1
		exit 1
	fi
	echo -e "Created snapshot $snap_id for volume $2" >>$1
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
        eval  "$3='$snap_id'"
}
createVolumeFromSnapshot() {
#####This function is used to create snapshot
###Usage
#createVolumeFromSnapshot logFile snap_id <vol_id>
# return value in <vol_id>
	###-----------------------------------------------------------------------------
	# create volume from snapshot
	###-----------------------------------------------------------------------------
	echo -e "\n*********Create volume from snapshot *********" >>$1
	result=`eval "$(./create_request.py "$compute_endpoint/?Action=CreateVolume&SnapshotId=$2&Version=$version")"`
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
        eval  "$3='$vol_id'"
}
attachVolume() {
	###-----------------------------------------------------------------------------
	#Attach volume to instance
	###-----------------------------------------------------------------------------
	echo -e "\n*********Attach volume $2 to instance $3*********" >>$1
	result=`eval "$(./create_request.py "$compute_endpoint/?Action=AttachVolume&InstanceId=$3&VolumeId=$2&Device=/dev/vdb&Version=$version")"`
	status=`echo $result|sed -n -e 's/.*<status>\(.*\)<\/status>.*/\1/p'`
	if [  -z "$status" ];
	then
	        echo -e "Attach volume failed.\n`date` Output is $result" >>$1
		exit 1
	fi
	echo -e "Attached volume $2 to instance $3" >>$1
	###-----------------------------------------------------------------------------
	# describe Volume 
	###-----------------------------------------------------------------------------
	checkStatus 0 $2 in-use $1 
	ret=$?
	if (($ret!= 0))
	then 
	        echo -e "Describe volume failed for in-use state at `date`" >>$1
		exit 1
	fi
}
detachVolume() {
	###-----------------------------------------------------------------------------
	# detach Volume 
	###-----------------------------------------------------------------------------
	echo -e "\n*********Detach volume $2 from instance $3*********" >>$1
	result=`eval "$(./create_request.py "$compute_endpoint/?Action=DetachVolume&InstanceId=$3&VolumeId=$2&Device=/dev/vdb&Version=$version")"`
	status=`echo $result|sed -n -e 's/.*<status>\(.*\)<\/status>.*/\1/p'`
	if [  -z "$status" ];
	then
	        echo -e "Detach Volume $2 failed.\n`date` Output is $result" >>$1
		exit 1
	fi
	###-----------------------------------------------------------------------------
	# describe volume 
	###-----------------------------------------------------------------------------
	checkStatus 0 $2 available $1 
	ret=$?
	if (($ret!= 0))
	then 
	        echo -e "Describe volume failed for available state at `date`" >>$1
		exit 1
	fi
	echo -e "Detached volume $2" >>$1
}
deleteVolume() {
	###-----------------------------------------------------------------------------
	# delete volume
	###-----------------------------------------------------------------------------
	echo -e "\n*********Delete volume $2*********" >>$1
	result=`eval "$(./create_request.py "$compute_endpoint/?Action=DeleteVolume&VolumeId=$2&Version=$version")"`
	status=`echo $result|sed -n -e 's/.*<return>\(.*\)<\/return>.*/\1/p'`
	if [  -z "$status" ];
	then
	        echo -e "Delete Volume $2 failed.\n`date` Output is $result" >>$1
		exit 1
	fi
	if [ "true" != $status ]
	then
	        echo -e "Delete Volume $2 still exists\n`date` Output is $result" >>$1
		exit 1
	fi
	
	echo -e "Deleting volume $2">>$1
	checkStatus 0 $2 invalid $1 
	ret=$?
	if (($ret!= 0))
	then 
	        echo -e "Delete volume failed $2 at `date`" >>$1
		exit 1
	else
		echo -e "Deleted volume $2">>$1
	fi
}

deleteSnapshot() {
	###-----------------------------------------------------------------------------
	# DeleteSnapshot S1 
	###-----------------------------------------------------------------------------
	echo -e "\n*********Delete snapshot $2*********" >>$1
	result=`eval "$(./create_request.py "$compute_endpoint/?Action=DeleteSnapshot&SnapshotId=$2&Version=$version")"`
	status=`echo $result|sed -n -e 's/.*<return>\(.*\)<\/return>.*/\1/p'`
	if [  -z "$status" ];
	then
	        echo -e "Delete snapshot failed.\n`date` Output is $result" >>$1
		exit 1
	fi
	if [ "true" != $status ]
	then
	        echo -e "Delete Snapshot $2 still exists\n`date` Output is $result" >>$1
		exit 1
	fi
	echo -e "Deleting snapshot $2">>$1
	checkStatus 2 $2 invalid $1 
	ret=$?
	if (($ret!= 0))
	then 
	        echo -e "Delete snapshot $2 failed at `date`" >>$1
		exit 1
	else
		echo -e "Deleted snapshot $2">>$1
	fi
}

terminateInstance() {
	###-----------------------------------------------------------------------------
	# DeleteInstance 
	###-----------------------------------------------------------------------------
	echo -e "\n*********Delete instance $2*********" >>$1
	result=`eval "$(./create_request.py "$compute_endpoint/?Action=TerminateInstances&InstanceId.1=$2&Version=$version")"`
	status=`echo $result|sed -n -e 's/.*<currentState>\(.*\)<\/currentState>.*/\1/p'`
	if [  -z "$status" ];
	then
	        echo -e "Terminate instance $2 failed.\n`date` Output is $result" >>$1
		exit 1
	fi
	if [ "shutting-down" != $status ]
	then
	        echo -e "Instance $2 still exists\n`date` Output is $result" >>$1
		exit 1
	fi
	echo "Shutting down instance $2" >> $1
	checkStatus 1 $2 invalid $1 
	ret=$?
	if (($ret!= 0))
	then 
	        echo -e "Terminate instance $2 failed at `date`" >>$1
		exit 1
	else
		echo -e "Terminated instance $2">>$1
	fi
}

createInstance() {
	####-----------------------------------------------------------------------------
	##Create an instance
	####-----------------------------------------------------------------------------
	echo -e "\nNEW SESSION STARTED" >>$1
	echo -e "\n*********Create Instance *********" >>$1
	result=`eval "$(./create_request.py "$compute_endpoint/?Action=RunInstances&ImageId=$image_id&KeyName=$keyName&InstanceTypeId=$inst_type&BlockDeviceMapping.1.DeleteOnTermination=True&BlockDeviceMapping.1.DeviceName=/dev/vda&Version=$version")"`
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
        eval  "$2='$inst_id'"
}

