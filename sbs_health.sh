##This is sbs health script which is invoked from run_health.sh
source sbs_functions.sh 
createInstance $1 inst_id
createVolume $1 $vol_size vol_id
attachVolume $1 $vol_id $inst_id
createSnapshot $1 $vol_id base_snap_id
createSnapshot $1 $vol_id snap_id
detachVolume $1 $vol_id $inst_id
deleteVolume $1 $vol_id 
createVolumeFromSnapshot $1 $snap_id vol_id
attachVolume $1 $vol_id $inst_id
detachVolume $1 $vol_id $inst_id
deleteVolume $1 $vol_id 
deleteSnapshot $1 $base_snap_id
deleteSnapshot $1 $snap_id
terminateInstance $1 $inst_id
