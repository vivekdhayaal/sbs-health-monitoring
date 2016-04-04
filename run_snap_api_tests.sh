#!/bin/bash

function notify_thru_email()
{
        #cat $2 |mail -s "[PROD]$1" -a "From: shishir.gowda@ril.com" shishir.gowda@ril.com
        cat $2 |mail -s "[PROD]$1" -a "From: shishir.gowda@ril.com" shishir.gowda@ril.com chirag.aggarwal@ril.com rahul4.jain@ril.com ravikanth.maddikonda@ril.com vivek.kayarohanam@ril.com sandeep41.kumar@ril.com
}

function notify_thru_email()
{
        cat $2 |mail -s "[PROD]$1" -a "From: shishir.gowda@ril.com" shishir.gowda@ril.com
}
script_sleep_min=1800
while :

do
	id=`date +%s`
	file="/tmp/snap_$id"
	echo -e "start time `date`" >> $file
	./snapshots_api.sh $file 
	echo -e "end time `date`" >> $file
	if (($? != 0))
	then
            notify_thru_email "ALERT: SNAP API failed" $file
	else
            notify_thru_email "SNAP API success" $file

	fi
	rm -rf $file
	sleep $script_sleep_min
done
