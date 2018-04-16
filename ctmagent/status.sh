#!/bin/bash
#==================================================================================================================================
# Usage  : Script to extract currently running robot status for a scenario.
# Version: 1.2 - Module Upgrade Option
#          1.1 - Initial Stable Version
# Date   : 16-04-2018
# Author : Sankar Mukherjee
#==================================================================================================================================

if [ $# -ne 1 ] ; then
        echo "ERROR: You need to pass Migration scenario to the script."
        exit 1
fi

scenro=$1
script_home=$(cd $(dirname $0);pwd)

if [ ! -f ${script_home}/run_upgrade_${scenro}.sh -o ! -d ${script_home}/${scenro} -o ! -d ${script_home}/log/${scenro} ] ; then
        echo "ERROR: Migration scanario does not exists!!!" 
        exit 1
fi
echo "========================================================================================================="
echo "=                               ControlM Migration Robot Status                                         ="
echo "========================================================================================================="
robot_pid=$(ps -ef | grep "robot.sh" | grep "$scenro" | grep -v grep | awk '{ print $2 }')
if [ -z "${robot_pid}" ] ; then
	echo "- No robot running for Scenario $scenro."
	exit 0
else
	robot_log=$(ls -ltr ${script_home}/log/${scenro}/robot_log_* | tail -1 | awk '{ print $9 }')
	if [ -f ${script_home}/stop.robot.${scenro} ] ; then
		tem_status=0
	else
		tem_status=1
	fi
	if [ $tem_status -eq 0 ] ; then
		term_ack=$(grep -q "Already requested termination" $robot_log ; echo $?)
	fi
	total_worker=0
	worker_pid=""
	for upscrpt_id in $(ps -ef | grep "run_upgrade_${scenro}" | grep "${robot_pid}" | grep -v grep | awk '{ print $2 }')
	do
		total_worker=$(expr $total_worker + 1)
		worker_pid="$upscrpt_id $worker_pid"
		host_start=$(grep "Starting to work with host" $robot_log | grep "${upscrpt_id}" | tail -1 | awk -F"-" '{ print $2 }' | awk -F"." '{ print $1 }')
		host_file=$(grep HOST_FILE_PASSED $robot_log | grep "${upscrpt_id}" | tail -1 | awk -F"=" '{ print $2 }')
		echo "PID: ${upscrpt_id}" > /tmp/status_hosts_$$_${upscrpt_id}.tmp
		echo "===============" >> /tmp/status_hosts_$$_${upscrpt_id}.tmp
		cat $host_file | sed 's/'${host_start}'/'${host_start}' </' >> /tmp/status_hosts_$$_${upscrpt_id}.tmp
	done
	echo ""
	echo "ROBOT PROCESS: $robot_pid"
	if [ $tem_status -ne 0 ] ; then
		echo "ROBOT STATUS: Running"
	elif [ $term_ack -ne 0 ] ; then
		echo "ROBOT STATUS: Running. Requested termination but not acknowledged by robot"
	else
		echo "ROBOT STATUS: Running. Acknowledged termination request"
	fi
	echo ""
	echo "TOTAL UPGRADE WORKER: ${total_worker}, PID: ${worker_pid}"
        echo ""
	echo "CURRENT WORKERS PROGRESS"
	echo "========================================================================================================="
        echo ""
	if [ $(ls -ltr /tmp/status_hosts_$$_* > /dev/null 2>&1 ; echo $?) -eq 0 ] ; then
		paste -d"\t" /tmp/status_hosts_$$_*
	fi
        echo ""
	echo "========================================================================================================="
	rm -f /tmp/status_hosts_$$_*
fi
