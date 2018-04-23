#!/bin/bash 
#==================================================================================================================================
# Usage  : Script to execute parallel batches of ControlM Upgrade Utility.
# Version: 1.2 - Module Upgrade Option
#          1.1 - Initial Stable Version
# Date   : 16-04-2018
# Author : Sankar Mukherjee
#==================================================================================================================================

# UTILITY FUNCTION
## Robot executor
robot(){

set -x

echo "NOTICE: Executing robot for Host File ${host_file}, ControlM Server ${auth_host}, Agent per batch ${host_in_batch}, Parallel Batched ${batchsz}, Probe interval ${sleep_time}."

if [ ! -f ${script_home}/run_upgrade_${scenro}.sh -o ! -d ${script_home}/${scenro} -o ! -d ${script_home}/log/${scenro} ] ; then
	echo "ERROR: Migration scanario does not exists!!!" 
	exit 1
elif [ ! -f ${host_file} ] ; then
	echo "ERROR: Host file provided doesnot exist!!!" 
        exit 1
elif [ -z "$batchsz" ]; then
        echo "ERROR: Batch size provided is empty!!!" 
        exit 1
elif [ $(test $batchsz -eq $batchsz ; echo $?) -ne 0 ] ; then
        echo "ERROR: Batch size provided is not a number!!!" 
        exit 1
elif [ $(ps -ef | grep "robot.sh" | grep "${scenro}" | grep -v $$ | grep -v grep | wc -l) -gt 0 ] ; then
	echo "ERROR: Another execution of robot script running for this scenario, two robot for same scenario cannot execute in parallel." 
	if [ ! -f ${script_home}/stop.robot.${scenro} ] ; then
		echo "ERROR: Another execution of robot script running for this scenario, two robot for same scenario cannot execute in parallel." 
	        echo "USAGE: Shutdown robot by creating a file in ${script_home} as stop.robot.${scenro}." 
		echo "USAGE: It generally takes an hour(maximum) for robot to wrap up all jobs." 
		exit 1
	else
		echo "We detected you already requested for robot stop but still robot continue, because you did not waited for robot to stop." 
		echo "Initiated robot kill... please wait." 
		robot_pid=$(ps -ef | grep "robot.sh" | grep "${scenro}" | grep -v $$ | grep -v grep | awk '{ print $2 }')
		tmp_to_hosts=${script_home}/DB/${scenro}/${auth_host}_todo
		robo_stat_file=${script_home}/kill.robot.${scenro}.${robot_pid}.status
		kill -9 ${robot_pid}
                echo "Killed robot with PID ${robot_pid}."
		echo "Initiated upgrade script kill... checking still executing upgrade script." 
		host_affected="${script_home}/DB/${scenro}/host_affcted_tmp_$$"
		host_notreported="${script_home}/DB/${scenro}/host_notreported_tmp_$$"
		host_notprocessed="${script_home}/DB/${scenro}/host_notprocessed_tmp_$$"
		host_reported="${script_home}/DB/${scenro}/host_reported_tmp_$$"
		ps -ef | grep "run_upgrade_${scenro}" | grep -v grep | awk '{ print $2 }' | while read upscrpt_id
		do
			echo "Starting to trigger kill for upgrade script with pid $upscrpt_id." 
			kill -9 $upscrpt_id
			p_robot_log=$(ls -ltr ${script_home}/log/${scenro}/robot_log_${robot_pid}_* | tail -1 | awk '{ print $9 }')
			p_trac_log=$(ls -ltr ${script_home}/log/${scenro}/ctmagent_upgrade_trace_${upscrpt_id}_* | tail -1 | awk '{ print $9 }')
			p_host_file=$(grep HOST_FILE_PASSED ${p_robot_log} | grep "${upscrpt_id}" | tail -1 | awk -F"=" '{ print $2 }')
			if [ ! -f $p_host_file -o ! -f $p_trac_log ] ; then
				echo "ERROR: Unable to trace execution of upgrade script with pid $upscrpt_id;" 
			else
				host_start=$(grep "Starting to work with host" ${p_robot_log} | grep "${upscrpt_id}" | tail -1 | awk -F"-" '{ print $2 }' | awk -F"." '{ print $1 }')
				host_complt=$(grep "Completed working with user" ${p_robot_log} | grep "${upscrpt_id}" | tail -1 | awk -F"-" '{ print $2 }' | awk -F"." '{ print $1 }')
				if [ "$host_start" != "$host_complt" ] ; then
					echo "$host_start" >> $host_affected
				fi
				cat $p_host_file | while read host_nm
				do
				  grep -q "$host_nm" $p_trac_log		
				  if [ $? -eq 0 ] ; then
				    echo "$host_nm,$(grep -q "$host_nm" $p_trac_log | awk -F"<td>" '{ print $4 }' | awk -F"</td>" '{ print $1 }')" >> $host_notreported
				  else
				    echo "$host_nm" >> $host_notprocessed
				  fi
				done
			fi	
		done
		echo "All currently executing upgrade has been killed. Generating report." 
		cat $tmp_to_hosts | while read host_nm
		do
			grep -q "$host_nm" $host_affected
			if [ $(grep -q "$host_nm" $host_affected ; echo $?) -eq 0 ] ; then
				echo "Host affected : $host_nm" 
			elif [ $(grep -q "$host_nm" $host_notreported ; echo $?) -eq 0 ] ; then
				echo "Host not reported : $host_nm" 
			elif [ $(grep -q "$host_nm" $host_notprocessed ; echo $?) -eq 0 ] ; then
				echo "Host not processed : $host_nm" 
			elif [ $(grep -q "$host_nm" ${script_home}/log/${scenro}/ctmagent_upgrade_trace_* ; echo $?) -eq 0 ] ; then
				echo "Host processed and reported : $host_nm" 
				echo "$host_nm" >> $host_reported
			else
				echo "Host not processed : $host_nm" 
				echo "$host_nm" >> $host_notprocessed
			fi
		done
		echo "**** OVERALL STATUS REPORT ****" >> $robo_stat_file
		echo "" >> $robo_stat_file
		echo "=====================================" >> $robo_stat_file
                echo "= Host Upgrade Incomplete            " >> $robo_stat_file
                echo "=====================================" >> $robo_stat_file
		cat $host_affected >> $robo_stat_file
                echo "=====================================" >> $robo_stat_file
                echo "= Host Upgrade Complete (Not Repored)" >> $robo_stat_file
                echo "=====================================" >> $robo_stat_file
		cat $host_notreported >> $robo_stat_file
                echo "=====================================" >> $robo_stat_file
                echo "= Host Upgrade Not Started           " >> $robo_stat_file
                echo "=====================================" >> $robo_stat_file
                cat $host_notprocessed >> $robo_stat_file
                echo "=====================================" >> $robo_stat_file
		rm -f $host_affected $host_notreported $host_notprocessed $host_reported
		echo "Completed cleanup of last execution and report stored in ${robo_stat_file}." 
		exit 2
	fi
fi

rm -rf ${script_home}/DB/${scenro}
mkdir -p ${script_home}/DB/${scenro}
cat ${host_file} > ${script_home}/DB/${scenro}/${auth_host}_todo
robot_id=$$
while true
do
	tot_process=$(ps -ef | grep "run_upgrade_${scenro}" | grep $robot_id | grep -v grep | wc -l)
	if [ -f ${script_home}/stop.robot.${scenro} -a $tot_process -ne 0 ] ; then
		echo "Already requested termination. Thus nothing to do." 
	elif [ -f ${script_home}/stop.robot.${scenro} -a $tot_process -eq 0 ] ; then
		echo "Already requested termination. Also all past batches completed thus exiting current execution." 
		exit 2
	else
		if [ $tot_process -eq $batchsz ] ; then
			echo "No more slot to execute batch. Thus nothing to do." 
		else
			nxt_batch_num=$(ls -ltr ${script_home}/DB/${scenro}/${auth_host}_batch_* 2> /dev/null | wc -l)
                        nxt_batch=${script_home}/DB/${scenro}/${auth_host}_batch_${nxt_batch_num}
			tot_host=$(cat ${script_home}/DB/${scenro}/${auth_host}_todo | wc -l)
			count=0
			counter=1
			while [ $counter -le $tot_host -a $count -lt $host_in_batch ]
			do
				host_nm=$(head -n $counter ${script_home}/DB/${scenro}/${auth_host}_todo | tail -1)
				echo "Host considered $host_nm, Counter $counter, Total Host Considered $count." 
				ls -ltr ${script_home}/DB/${scenro}/${auth_host}_batch_* > /dev/null 2>&1
				if [ $? -ne 0 ] ; then
					echo "Host $host_nm added to $nxt_batch." 
					echo $host_nm >> $nxt_batch
					count=$(expr $count + 1)
				elif [ $(grep -q "$host_nm" ${script_home}/DB/${scenro}/${auth_host}_batch_* ; echo $?) -ne 0 ] ; then
                                        echo "Host $host_nm added to $nxt_batch." 
					echo $host_nm >> $nxt_batch
					count=$(expr $count + 1)
				fi
				counter=$(expr $counter + 1)
			done
			if [ ! -f ${nxt_batch} ] ; then
				echo "No new host to process. Execution complete!!!" 
				exit 0
			else
				echo "Initiating new batch with host file $nxt_batch." 
				${script_home}/run_upgrade_${scenro}.sh $nxt_batch &
			fi
		fi
	fi
	echo "Completed current batch execution cycle at $(date). Now will sleep." 
	sleep ${sleep_time}m
done

}

usage()
{
    echo "USAGE: robot.sh -s scenario -h hostfile [-b batchsize]"
    echo "       - Scenario should exist currently. Mandatory parameter."
    echo "       - Host file should be named after the ControlM Authorized Servers for the Agent. Mandatory parameter."
    echo "       - Parallel batches to execute current scenario. Optional parameter."
}

# MAIN 

## Command line processing
while [ "$1" != "" ]; do
    case $1 in
        -s ) shift
             scenro=$1
             ;;
        -h ) shift
             host_file=$1
             ;;
        -b ) shift
             batchsz=$1
             ;;
        * )  usage
             exit 1
    esac
    shift
done

if [ -z "$scenro" ] ; then
	usage
	exit 1
fi 

if [ -z "$host_file" ] ; then
        usage
        exit 1
fi

if [ -z "$batchsz" ] ; then
        batchsz=2
fi

## Environment setup
auth_host=$(basename ${host_file})
host_in_batch=5
sleep_time=5
script_home=$(cd $(dirname $0);pwd)
today_dt=$(date +%F-%H-%M)
robot_log="${script_home}/log/${scenro}/robot_log_$$_${today_dt}.log"

## Robot execution
robot > $robot_log 2>&1
