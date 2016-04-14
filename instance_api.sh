required_status='running'
loop=true
inst_id=`eval "$(./create_request.py "https://compute.ind-west-1.internal.jiocloudservices.com/?Action=RunInstances&ImageId=jmi-74710812&KeyName=health_key&InstanceTypeId=c1.medium&BlockDeviceMapping.1.DeleteOnTermination=True&Version=2016-03-01")"|sed -n -e 's/.*<instanceId>\(.*\)<\/instanceId>.*/\1/p'`
if (($? != 0))
then
        echo -e "Create instance failed" >>$1
fi
echo "*********instance id: $inst_id********"
echo -e "Instanceid: $inst_id" >>$1
count=0
status=""
sleep 20
while (($count != 20)); do
status=`eval "$(./create_request.py "https://compute.ind-west-1.internal.jiocloudservices.com/?Action=DescribeInstances&Version=2016-03-01&InstanceId.1=$inst_id")"|sed -n -e 's/.*<instanceState>\(.*\)<\/instanceState>.*/\1/p'`
#eval "$(./create_request.py "https://vpc.ind-west-1.internal.jiocloudservices.com/?Action=AssociateAddress&AllocationId=eipalloc-7053b714&InstanceId=i-8d1b7a11&Version=2016-03-01")"

if (($? != 0))
then
        echo -e "Describe instance $inst_id failed" >>$1
fi

create=1
if [ "$status" = "$required_status" ];
then
	create=0
	count=20
else
	sleep 5
        count=$((count+1))
fi

done

echo -e "status: $status" >>$1
echo "### instance $inst_id status: $status ###"
if (($create != 0))
then
        echo -e "Create instance $inst_id stuck" >>$1
fi

del=1
eval "$(./create_request.py "https://compute.ind-west-1.internal.jiocloudservices.com/?Action=TerminateInstances&InstanceId.1=$inst_id&Version=2016-03-01")"
if (($? == 0))
then
	del=0
else
	echo -e "Delete instance $inst_id failed" >>$1	
fi

exit $((del || create))
