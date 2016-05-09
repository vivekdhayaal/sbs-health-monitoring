#!/bin/bash
#source /home/block_team/client_v2_jcs_scripts/openrc_test
function notify_thru_email1()
{
        cat $2 |mail -s "[PROD]$1" -a "From: jcs.sbsnotifications@zmail.ril.com" shishir.gowda@ril.com chirag.aggarwal@ril.com rahul4.jain@ril.com ravikanth.maddikonda@ril.com vivek.kayarohanam@ril.com sandeep41.kumar@ril.com souvik.ray@ril.com
}

function notify_thru_email()
{
	time=$(date +%k%M)
	if [[ "$time" -ge 1215 ]] && [[ "$time" -le 1218 ]];then
        	cat $2 |mail -s "[PROD]$1" -a "From: jcs.sbsnotifications@zmail.ril.com" shishir.gowda@ril.com chirag.aggarwal@ril.com rahul4.jain@ril.com ravikanth.maddikonda@ril.com vivek.kayarohanam@ril.com sandeep41.kumar@ril.com souvik.ray@ril.com
	else
	        cat $2 |mail -s "[PROD]$1" -a "From: jcs.sbsnotifications@zmail.ril.com" sandeep41.kumar@ril.com chirag.aggarwal@ril.com
	fi
}
script_interval=60
curr_sleep_interval=$script_interval
max_failures=5
max_script_interval=3600
failures=0
failCount=0
passCount=0
to_send=0
while :

do
	time=$(date +%k%M)
	if [[ "$time" -ge 2300 ]] ;then
	    to_send=1
	fi
	if [[ "$time" -le 0100 ]] ;then
	    if(($to_send==1))
	    then
	      file_summary="/tmp/inst_summary"
	      echo -e "Total number of Pass:$passCount " >> $file_summary
	      echo -e "Total number of Fail:$failCount " >> $file_summary
   	      echo -e "\n---Test Scenario---\nCreate Instance I1\nCreate Volume V1\nAttach Volume V1 to instance I1\nCreate base snapshot B1 for volume V1\nCreate incremental snapshot B2 for volume V1\nDetach volume V1\nDelete volume V1\nCreate volume V2 from snapshot B2\nAttach volume V2 to instance I1\nDetach volume V2 from instance I1\nDelete volume V2\nDelete base snapshot B1\nDelete incremental snapshot B2\nDelete instance I1" >> $file_summary
	      notify_thru_email1 "Instance API daily summary" $file_summary
	      to_send=0
	      rm -rf $file_summary
	    fi
        fi

	id=`date +"%y-%m-%d-%H-%M-%S"`
	file="/tmp/inst-$id"
	echo -e "start time `date`" >> $file
	./health.sh $file 
        if (($? != 0))
	then
	    failCount=$(($failCount+1))
	    echo -e "end time `date`" >> $file
            notify_thru_email1 "ALERT: Instance API failed" $file
	    failures=$(($failures+1))
	else
	    passCount=$(($passCount+1))
	    echo -e "end time `date`" >> $file
            if(($failures!=0))
	    then
                notify_thru_email1 "Instance API success" $file
	    else		
                notify_thru_email "Instance API success" $file
	    fi
	    failures=0
	    curr_sleep_interval=$script_interval
	fi
	echo "deleting file $file"
	rm -rf $file
	if (($failures>=$max_failures))
	then
                echo "Delay the script" 

		if (($curr_sleep_interval>$max_script_interval))
		then
			curr_sleep_interval=$max_script_interval
		else
  			curr_sleep_interval=$(($curr_sleep_interval*2))
 		fi
	fi
	sleep $curr_sleep_interval
done
