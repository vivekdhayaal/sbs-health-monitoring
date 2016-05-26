# A shell script to clean up resources for a instance failure caused by our health scripts 
# it need a argument specifying the file to clean up
# How to run: ./clean.sh /tmp/16-05-20/08-20-15
# It will save the cleanup logs in /tmp/logFile

IFS=$'\n'
content=( $(cat $1))
content_length=${#content[@]}
vol_index=0
snap_index=0
detach_index=0
log='/tmp/logFile'
source sbs_functions.sh 
##Reading the cleanup file in reverse order 
##to make sure all resource are cleaned up before deleting the instance.
##it also check if a resource is already deleted or detached then it will not make unnecessary calls
for (( i=(content_length- 1);i>=0;i--))
do
    IFS=$' '
    to_clean=1
    my_arr=(${content[$i]})
    command="${my_arr[0]} ${my_arr[1]}"
    if [ "$command" == "Created volume" ]
    then
        for (( v=0; v < vol_index;v++ ))
	do
            if [ "${volumes[v]}" == "${my_arr[2]}" ]
	    then
		to_clean=0
   	    fi
	done
	if (($to_clean==1))
	then
    	echo "delete volume ${my_arr[2]}"
	deleteVolume $log ${my_arr[2]}
	fi
    fi
    if [ "$command" == "Created instance" ]
    then
    	echo "delete instance ${my_arr[2]}"
	terminateInstance $log ${my_arr[2]}
    fi
    if [ "$command" == "Attached volume" ]
    then
        for (( v=0; v < detach_index;v++ ))
	do
            if [ "${detached[v]}" == "${my_arr[2]}" ]
	    then
		to_clean=0
   	    fi
	done
	if (($to_clean==1))
	then
    	    echo "Detach volume ${my_arr[2]}"
	    detachVolume $log ${my_arr[2]} ${my_arr[5]}
	fi
    fi
    if [ "$command" == "Created snapshot" ]
    then
        for (( v=0; v < snap_index;v++ ))
	do
            if [ "${snapshots[v]}" == "${my_arr[2]}" ]
	    then
		to_clean=0
   	    fi
	done
	if (($to_clean==1))
	then
    	echo "Delete snapshot ${my_arr[2]}"
	deleteSnapshot $log ${my_arr[2]}
	fi
    fi
    if [ "$command" == "Deleted volume" ]
    then
	volumes[vol_index]=${my_arr[2]}
	vol_index=$vol_index+1
    fi
    if [ "$command" == "Deleted snapshot" ]
    then
	snapshots[snap_index]=${my_arr[2]}
	snap_index=$snap_index+1
    fi
    if [ "$command" == "Detached volume" ]
    then
	detached[detach_index]=${my_arr[2]}
	detach_index=$detach_index+1
    fi
done
#rm -rf $1
