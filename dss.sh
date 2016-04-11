#!/bin/bash

function notify_thru_email()
{
        #cat $2 |mail -s "[PROD]$1" -a "From: shishir.gowda@ril.com" shishir.gowda@ril.com
        cat $2 |mail -s "[PROD]$1" -a "From: shishir.gowda@ril.com" shishir.gowda@ril.com chirag.aggarwal@ril.com rahul4.jain@ril.com ravikanth.maddikonda@ril.com vivek.kayarohanam@ril.com sandeep41.kumar@ril.com
}

script_sleep_min=60

while :

do
	rm /tmp/dss.health
	python ./dss_check.py &>>/tmp/dss.health
	if (($? != 0))
	then
            echo -n "${output}" >> /tmp/dss.health
            notify_thru_email "ALERT: DSS not available" /tmp/dss.health
	fi

	sleep $script_sleep_min
done
