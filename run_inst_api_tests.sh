#!/bin/bash

function notify_thru_email()
{
        #cat $2 |mail -s "[PROD]$1" -a "From: shishir.gowda@ril.com" shishir.gowda@ril.com
        cat $2 |mail -s "[PROD]$1" -a "From: sandeep41.kumar@ril.com" sandeep41.kumar@ril.com
shishir.gowda@ril.com chirag.aggarwal@ril.com rahul4.jain@ril.com ravikanth.maddikonda@ril.com vivek.kayarohanam@ril.com sandeep41.kumar@ril.com
}

function notify_thru_email()
{
        cat $2 |mail -s "[PROD]$1" -a "From: sandeep41.kumar@ril.com" sandeep41.kumar@ril.com
}
script_sleep_min=3600
while :

do
	id=`date +%s`
	file="/tmp/$id"
	echo -e "start time `date`" >> $file
	./instance_api.sh $file 
	if (($? != 0))
	then
            notify_thru_email "ALERT: Instance API failed" $file
	else
            notify_thru_email "Instance API success" $file

	fi
	echo -e "end time `date`" >> $file
	rm -rf $file
	sleep $script_sleep_min
done
