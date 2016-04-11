required_status='available'
loop=true
volid=`eval "$(./create_request.py "https://compute.ind-west-1.internal.jiocloudservices.com/?Action=CreateVolume&Size=1&Version=2016-03-01")"|sed -n -e 's/.*<volumeId>\(.*\)<\/volumeId>.*/\1/p'`
if (($? != 0))
then
        echo -e "Create volume failed" >>$1
fi
echo "*********volume id: $volid ********"
echo -e "Volumeid: $volid" >>$1
count=0
status=""
while (($count != 20)); do
status=`eval "$(./create_request.py "https://compute.ind-west-1.internal.jiocloudservices.com/?Action=DescribeVolumes&Version=2016-03-01&VolumeId=$volid")"|sed -n -e 's/.*<status>\(.*\)<\/status>.*/\1/p'`

if (($? != 0))
then
        echo -e "Describe volume $volid failed" >>$1
fi

create=1
if [ "$status" = "$required_status" ];
then
	create=0
	count=20
else
	sleep 2
        count=$((count+1))
fi

done

echo -e "status: $status" >>$1
echo "### volume $volid status: $status ###"
if (($create != 0))
then
        echo -e "Create volume $volid stuck" >>$1
fi
##create snapshot

snapid=`eval "$(./create_request.py "https://compute.ind-west-1.internal.jiocloudservices.com/?Action=CreateSnapshot&VolumeId=$volid&Version=2016-03-01")"|sed -n -e 's/.*<snapshotId>\(.*\)<\/snapshotId>.*/\1/p'`
echo "******* snap id : $snapid **************"
echo -e "Snapid: $snapid" >> $1

required_status="completed"
while (($count != 60)); do
status=`eval "$(./create_request.py "https://compute.ind-west-1.internal.jiocloudservices.com/?Action=DescribeSnapshots&Version=2016-03-01&SnapshotId=$snapid")"|sed -n -e 's/.*<status>\(.*\)<\/status>.*/\1/p'`
echo $status
if (($? != 0))
then
        echo -e "Describe Snapshot $snapid failed" >>$1
fi

snap_create=1
if [ "$status" = "$required_status" ];
then
        snap_create=0
        count=60
else
        sleep 2
        count=$((count+1))
fi

done
echo -e "snapshot status $status" >> $1
snap_del=1
eval "$(./create_request.py "https://compute.ind-west-1.internal.jiocloudservices.com/?Action=DeleteVolume&VolumeId=$volid&Version=2016-03-01")"
if (($? == 0))
then
	del=0
else
	echo -e "Delete volume $volid failed" >>$1	
fi

sleep 20

snap_del=1
eval "$(./create_request.py "https://compute.ind-west-1.internal.jiocloudservices.com/?Action=DeleteSnapshot&SnapshotId=$snapid&Version=2016-03-01")"
if (($? == 0))
then
	snap_del=0
else
	echo -e "Delete Snap $snapid failed" >>$1	
fi

exit $((del || create || snap_create || snap_del))
