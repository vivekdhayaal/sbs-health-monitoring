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

del=1
eval "$(./create_request.py "https://compute.ind-west-1.internal.jiocloudservices.com/?Action=DeleteVolume&VolumeId=$volid&Version=2016-03-01")"
if (($? == 0))
then
	del=0
else
	echo -e "Delete volume $volid failed" >>$1	
fi

exit $((del || create))
