#!/bin/bash 
#==================================================================================================================================
# Usage  : Script to execute parallel batches of ControlM Upgrade Utility.
# Version: 1.0
# Date   : 21-03-2018
# Author : Sankar Mukherjee
#==================================================================================================================================

scenro=$1
batchsz=$2
host_file=$3
host_in_batch=2
sleep_time=5
script_home=$(cd $(dirname $0);pwd)
today_dt=$(date +%F-%H-%M)
robot_log="${script_home}/log/${scenro}/robot_log_$$_${today_dt}.log"

if [ ! -f ${script_home}/run_upgrade_${scenro}.sh -o ! -d ${script_home}/${scenro} -o ! -d ${script_home}/log/${scenro} ] ; then
	echo "ERROR: Migration scanario does not exists!!!" >> $robot_log
	exit 1
elif [ ! -f ${host_file} ] ; then
	echo "ERROR: Host file provided doesnot exist!!!" >> $robot_log
        exit 1
elif [ -z "$batchsz" ]; then
        echo "ERROR: Batch size provided is empty!!!" >> $robot_log
        exit 1
elif [ $(test $batchsz -eq $batchsz ; echo $?) -ne 0 ] ; then
        echo "ERROR: Batch size provided is not a number!!!" >> $robot_log
        exit 1
elif [ $(ps -ef | grep "robot.sh" | grep "${scenro}" | grep -v $$ | grep -v grep | wc -l) -gt 0 ] ; then
	echo "ERROR: Another execution of robot script running for this scenario, two robot for same scenario cannot execute in parallel." >> $robot_log
	if [ ! -f ${script_home}/stop.robot.${scenro} ] ; then
		echo "ERROR: Another execution of robot script running for this scenario, two robot for same scenario cannot execute in parallel." >> $robot_log
	        echo "USAGE: Shutdown robot by creating a file in ${script_home} as stop.robot.${scenro}." >> $robot_log
		echo "USAGE: It generally takes an hour(maximum) for robot to wrap up all jobs." >> $robot_log
		exit 1
	else
		echo "We detected you already requested for robot stop but still robot continue, because you did not waited for robot to stop." >> $robot_log
		echo "Initiated robot kill... please wait." >> $robot_log
		robot_pid=$(ps -ef | grep "robot.sh" | grep "${scenro}" | grep -v $$ | grep -v grep | awk '{ print $2 }')
		tmp_to_hosts=${script_home}/DB/${scenro}/host.todo
		robo_stat_file=${script_home}/kill.robot.${scenro}.${robot_pid}.status
		kill -9 ${robot_pid}
		echo "Initiated upgrade script kill... checking still executing upgrade script." >> $robot_log
		host_affected="${script_home}/DB/${scenro}/host.affcted.tmp.$$"
		host_notreported="${script_home}/DB/${scenro}/host.notreported.tmp.$$"
		host_notprocessed="${script_home}/DB/${scenro}/host.notprocessed.tmp.$$"
		host_reported="${script_home}/DB/${scenro}/host.reported.tmp.$$"
		ps -ef | grep "run_upgrade_${scenro}" | grep -v grep | awk '{ print $2 }' | while read upscrpt_id
		do
			echo "Starting to trigger kill for upgrade script with pid $upscrpt_id." >> $robot_log
			kill -9 $upscrpt_id
			p_robot_log=$(ls -ltr ${script_home}/log/${scenro}/robot_log_${robot_pid}_* | tail -1 | awk '{ print $9 }')
			p_trac_log=$(ls -ltr ${script_home}/log/${scenro}/ctmagent_upgrade_trace_${upscrpt_id}_* | tail -1 | awk '{ print $9 }')
			p_host_file=$(grep HOST_FILE_PASSED ${p_robot_log} | grep "${upscrpt_id}" | tail -1 | awk -F"=" '{ print $2 }')
			if [ ! -f $p_host_file -o ! -f $p_trac_log ] ; then
				echo "ERROR: Unable to trace execution of upgrade script with pid $upscrpt_id;" >> $robot_log
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
		echo "All currently executing upgrade has been killed. Generating report." >> $robot_log
		cat $tmp_to_hosts | while read host_nm
		do
			grep -q "$host_nm" $host_affected
			if [ $(grep -q "$host_nm" $host_affected ; echo $?) -eq 0 ] ; then
				echo "Host affected : $host_nm" >> $robot_log
			elif [ $(grep -q "$host_nm" $host_notreported ; echo $?) -eq 0 ] ; then
				echo "Host not reported : $host_nm" >> $robot_log
			elif [ $(grep -q "$host_nm" $host_notprocessed ; echo $?) -eq 0 ] ; then
				echo "Host not processed : $host_nm" >> $robot_log
			elif [ $(grep -q "$host_nm" ${script_home}/log/${scenro}/ctmagent_upgrade_trace_* ; echo $?) -eq 0 ] ; then
				echo "Host processed and reported : $host_nm" >> $robot_log
				echo "$host_nm" >> $host_reported
			else
				echo "Host not processed : $host_nm" >> $robot_log
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
		echo "Completed cleanup of last execution and report stored in ${robo_stat_file}." >> $robot_log
		exit 2
	fi
fi

rm -rf ${script_home}/DB/${scenro}
mkdir -p ${script_home}/DB/${scenro}
cat ${host_file} > ${script_home}/DB/${scenro}/host.todo
robot_id=$$
while true
do
	tot_process=$(ps -ef | grep "run_upgrade_${scenro}" | grep $robot_id | grep -v grep | wc -l)
	if [ -f ${script_home}/stop.robot.${scenro} -a $tot_process -ne 0 ] ; then
		echo "Already requested termination. Thus nothing to do." >> $robot_log
	elif [ -f ${script_home}/stop.robot.${scenro} -a $tot_process -eq 0 ] ; then
		echo "Already requested termination. Also all past batches completed thus exiting current exeution." >> $robot_log
		exit 2
	else
		if [ $tot_process -eq $batchsz ] ; then
			echo "No more slot to execute batch. Thus nothing to do." >> $robot_log
		else
			nxt_batch_num=$(ls -ltr ${script_home}/DB/${scenro}/host.batch.* 2> /dev/null | wc -l)
                        nxt_batch=${script_home}/DB/${scenro}/host.batch.${nxt_batch_num}
			tot_host=$(cat ${script_home}/DB/${scenro}/host.todo | wc -l)
			count=0
			counter=1
			while [ $counter -le $tot_host -a $count -lt $host_in_batch ]
			do
				host_nm=$(head -n $counter ${script_home}/DB/${scenro}/host.todo | tail -1)
				echo "Host considered $host_nm, Counter $counter, Total Host Considered $count." >> $robot_log
				ls -ltr ${script_home}/DB/${scenro}/host.batch.* > /dev/null 2>&1
				if [ $? -ne 0 ] ; then
					echo "Host $host_nm added to $nxt_batch." >> $robot_log
					echo $host_nm >> $nxt_batch
					count=$(expr $count + 1)
				elif [ $(grep -q "$host_nm" ${script_home}/DB/${scenro}/host.batch.* ; echo $?) -ne 0 ] ; then
                                        echo "Host $host_nm added to $nxt_batch." >> $robot_log
					echo $host_nm >> $nxt_batch
					count=$(expr $count + 1)
				fi
				counter=$(expr $counter + 1)
			done
			if [ ! -f ${nxt_batch} ] ; then
				echo "No new host to process. Execution complete!!!" >> $robot_log
				exit 0
			else
				echo "Initiating new batch with host file $nxt_batch." >> $robot_log
				${script_home}/run_upgrade_${scenro}.sh $nxt_batch >> $robot_log 2>> $robot_log &
			fi
		fi
	fi
	echo "Completed current batch execution cycle at $(date). Now will sleep." >> $robot_log
	sleep ${sleep_time}m
done
