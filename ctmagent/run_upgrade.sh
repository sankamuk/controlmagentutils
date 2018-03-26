#!/bin/bash
#==================================================================================================================================
# Usage  : Script to upgrade controlM agent in batch. Argument: File with list of agent host to patch.
# Version: 1.0
# Date   : 21-03-2018
# Author : Sankar Mukherjee
#==================================================================================================================================

# COMANND LINE ARGUMENT
host_file=$?

# UTILITY FUNCTION
## Mailing Utility
mail_report(){
	echo "[`date`] Starting to notify user."
        action_to=$1
        action_data=$2
	mail_file=/tmp/run_upgrade.mail.tmp.$$
	if [ "$action_to" == "ALERT" ] ; then
		echo "[`date`] Requested to send critical alert notification with details ${action_data}."
		_agnt_host=$(echo ${action_data} | awk -F"@@@" '{ print $1 }')
                _agnt_user=$(echo ${action_data} | awk -F"@@@" '{ print $2 }')
		echo "<html><body><h1><center>ControlM Upgrade Tool</center></h1><br><br><table style="width:80%"  border="1" align="center"><tr><td style="width:40%" bgcolor="AFBCBE">Date</td><td>$(date)</td></tr><tr><td style="width:40%" bgcolor="AFBCBE">Host Affected</td><td>${_agnt_host}</td></tr><tr><td style="width:40%" bgcolor="AFBCBE">Agent User</td><td>${_agnt_user}</td></tr></table><br><br></body></html>" > $mail_file
		mail_subject="ALERT: Agent upgrade had issue on host ${_agnt_host}. Urgent action required."
	elif [ "$action_to" == "REPORT" ] ; then
                echo "[`date`] Requested to send final report of upgrade."
		if [ -f ${action_data} ] ; then
			cat ${action_data} > $mail_file
                        mail_subject="REPORT: Agent upgrade had completed. Check report for any failure."
		else
			echo "<html><body><h1><center>ControlM Upgrade Tool</center></h1><br><br><table style="width:80%"  border="1" align="center"><tr><td style="width:40%" bgcolor="AFBCBE">Upgrade completed but cannot find report file</td></tr></table><br><br></body></html>" > $mail_file
			mail_subject="REPORT: Agent upgrade had completed. Check report for any failure."
		fi
	fi
	(
        echo To: ${email_id}
        echo From: CTMAdmin
        echo "Content-Type: text/html; "
        echo "Subject: ${mail_subject}"
        echo ""
        cat ${mail_file}
        ) | /usr/sbin/sendmail -t

	rm -f ${mail_file}
        echo "[`date`] Completed user nitification."
}

## Upgrade utility
run_action_on_host(){
 os_type=$1
 host_nm=$2
 run_user=$3
 user_pass=$4
 tmp_file=${log_home}/run_action_on_host.${host_nm}.${run_user}.${today_dt}.tmp.$$
 echo "[`date`] Check agent configuration status for ${host_nm} with user ${run_user}."

 sshpass -p "${user_pass}" ssh -o StrictHostKeyChecking=no ${run_user}@${host_nm} "ag_diag_comm" > ${tmp_file} 2>&1
 if [ $? -ne 0 ] ; then
  echo "[`date`] ERROR - Unable to execute remote command on host."
  echo "<tr><td>${host_nm}</td><td>${os_type}</td><td>${run_user}</td><td>Failed</td></tr>" >> ${exec_trace}
 else
  agnt_usr=$(grep "Agent User Name" ${tmp_file} | awk -F":" '{ print $2 }' | xargs)
  agnt_vsn=$(grep "Agent Version" ${tmp_file} | awk -F":" '{ print $2 }' | xargs)
  agnt_cntl_host=$(grep "Authorized Servers Host Names" ${tmp_file} | awk -F":" '{ print $2 }' | xargs)
  run_as=$(grep "Agent Listener" ${tmp_file} | awk -F"(" '{ print $1 }' | awk -F"Running as" '{ print $2 }' | xargs)
  agnt_lnr_stat=$(grep "Agent Listener" ${tmp_file} | awk -F":" '{ print $2 }' | grep -q "Not running"; echo $?)
  agnt_trc_stat=$(grep "Agent Tracker" ${tmp_file} | awk -F":" '{ print $2 }' | grep -q "Not running"; echo $?)
  rm -f ${tmp_file}
  if [ "$agnt_usr" != "${run_user}" ] ; then
   echo "[`date`] Agent not configured with this user."
   echo "<tr><td>${host_nm}</td><td>${os_type}</td><td>${run_user}</td><td>NA</td></tr>" >> ${exec_trace}
  else
   echo "$agnt_vsn" | grep -q "${curnt_version}"
   if [ $? -ne 0 ] ; then
    echo "[`date`] Agent current version not ${curnt_version} thus no upgrade required."
    echo "<tr><td>${host_nm}</td><td>${os_type}</td><td>${run_user}</td><td>NA</td></tr>" >> ${exec_trace}
   else
    if [ $agnt_lnr_stat -eq 0 -o $agnt_trc_stat -eq 0 ] ; then
     echo "[`date`] Agent currently not running. Thus probably decommisioned."
     echo "<tr><td>${host_nm}</td><td>${os_type}</td><td>${run_user}</td><td>NA</td></tr>" >> ${exec_trace}
    else
     case $os_type in
     Linux)
       sshpass -p "${user_pass}" ssh -o StrictHostKeyChecking=no ${run_user}@${host_nm} "wget http://${bin_host}/${download_home}/linux/upgrade.sh -O ~/upgrade.sh"
       dwn_exec_stat=$?
       ;;
     HP-UX)
       sshpass -p "${user_pass}" ssh -o StrictHostKeyChecking=no ${run_user}@${host_nm} "/opt/perl/bin/lwp-download http://${bin_host}/${download_home}/hpux/upgrade.sh ~/upgrade.sh"
       dwn_exec_stat=$?
       ;;
     esac
     if [ $dwn_exec_stat -ne 0 ] ; then
         echo "[`date`] ERROR - Unable to download upgrade script in agent host."
         echo "<tr><td>${host_nm}</td><td>${os_type}</td><td>${run_user}</td><td>Failed</td></tr>" >> ${exec_trace}
     else
         sshpass -p "${user_pass}" ssh -o StrictHostKeyChecking=no ${run_user}@${host_nm} "chmod a+rx ~/upgrade.sh"
         if [ $? -ne 0 ] ; then
           echo "[`date`] ERROR - Unable to set correct permission to upgrade script in agent host."
           echo "<tr><td>${host_nm}</td><td>${os_type}</td><td>${run_user}</td><td>Failed</td></tr>" >> ${exec_trace}
         else
           sshpass -p "${user_pass}" ssh -o StrictHostKeyChecking=no ${run_user}@${host_nm} "~/upgrade.sh upgrade_agent ${agnt_cntl_host} ${run_user} ${run_as}"
           if [ $? -ne 0 ] ; then
             echo "[`date`] ERROR - Failed to upgrade agent. Initiating rollback."
             sshpass -p "${user_pass}" ssh -o StrictHostKeyChecking=no ${run_user}@${host_nm} "~/upgrade.sh is_started ${agnt_cntl_host} ${run_user} ${run_as}"
             if [ $? -eq 0 ] ; then
               echo "[`date`] ERROR - Rollback happened successfully. Agent currently running."
               echo "<tr><td>${host_nm}</td><td>${os_type}</td><td>${run_user}</td><td>Failed</td></tr>" >> ${exec_trace}
             else
               sshpass -p "${user_pass}" ssh -o StrictHostKeyChecking=no ${run_user}@${host_nm} "~/upgrade.sh rollback_agent ${agnt_cntl_host} ${run_user} ${run_as}"
               if [ $? -ne 0 ] ; then
                 echo "[`date`] ERROR - Rollback unsuccessfull. Raising concerned as agent state unstable."
                 echo "<tr><td>${host_nm}</td><td>${os_type}</td><td>${run_user}</td><td>Critical Failure</td></tr>" >> ${exec_trace}
                 mail_report "ALERT" "${host_nm}@@@${run_user}"
               else
                 echo "[`date`] ERROR - Rollback happened successfully. Agent currently running."
                 echo "<tr><td>${host_nm}</td><td>${os_type}</td><td>${run_user}</td><td>Failed</td></tr>" >> ${exec_trace}
               fi
             fi
           else
             echo "[`date`] Agent upgrade successful."
             echo "<tr><td>${host_nm}</td><td>${os_type}</td><td>${run_user}</td><td>Success</td></tr>" >> ${exec_trace}
           fi
         fi
       fi
    fi
   fi
  fi
 fi
 echo "[`date`] Working on host ${host_nm} with user ${run_user} of type ${os_type}."
}


# MAIN MODULE
## Environment validation
ls -ltr `which keypass` >/dev/null 2>&1
if [ $? -ne 0 ] ; then
	echo "[`date`] ERROR - Unable to find keypass binary. It is one of the requirement."
	exit 1
fi
if [ ! -f ${host_file} ] ; then
        echo "[`date`] ERROR - Unable to find host file."
        exit 1
fi

## Environment setup
bin_host=@@@BINARY_HOST@@@
download_home="ctmagent/v9p4"
curnt_version="7.0"
email_id=sanmuk21@gmail.com
today_dt=$(date +%F-%H-%M)
status_file="${host_file}.result"
script_home=$(cd $(dirname $0);pwd)
log_home="${script_home}/log/"
[ -d ${log_home} ] && mkdir -p ${log_home}
exec_trace=${log_home}/ctmagent_upgrade_trace_${today_dt}.log

## Notification setup
echo "<html><body><h1><center>ControlM Upgrade Tool</center></h1><br><br>" >> ${exec_trace}
echo "<table style="width:80%"  border="1" align="center"><tr><td style="width:40%" bgcolor="AFBCBE">Date</td><td>${today_dt}</td></tr><tr><td style="width:40%" bgcolor="AFBCBE">Execution Host</td><td>$(hostname)</td></tr><tr><td style="width:40%" bgcolor="AFBCBE">Log Location</td><td>${log_home}</td></tr></table><br><br>" >> ${exec_trace}
echo "<table style="width:80%"  border="1" align="center"><tr bgcolor="BBF1FA">" >> ${exec_trace}
echo "<th>Host</th><th>OS</th><th>User</th><th>Upgrade Status</th></tr>" >> ${exec_trace}

## Execute upgrade from host file
cat ${host_file} | while read host_name
do
	echo "[`date`] Starting to work with host $host_name."
	hst_log_file=${log_home}/ctmagent_upgrade_${host_name}_${today_dt}.log
	echo "[`date`] Checking setup with user - ctmhp7."
	os_type=$(sshpass -p "ctmagent" ssh -o StrictHostKeyChecking=no ctmhp7@${host_name} "uname | awk '{ print $1 }'")
	if [ $? -eq 0 ] ; then
		echo "[`date`] Successfully tested host access. Executing upgrade action."
		run_action_on_host "$os_type" "$host_name" "ctmhp7" "ctmagent" > ${hst_log_file} 2>&1
		echo "[`date`] Completed action."
	fi
	echo "[`date`] Completed working with user - ctmhp7."
	echo "[`date`] Completed working with host $host_name."
done		
echo "</table></body></html>" >> ${exec_trace}
 
## Send report
mail_report "REPORT" ${exec_trace}
