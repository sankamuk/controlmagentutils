#!/bin/sh -x
#==================================================================================================================================
# Usage  : Script to patch controlM agent. Platfom: Linux
# Version: 1.2 - Module Upgrade Option
#          1.1 - Initial Stable Version
# Date   : 16-04-2018
# Author : Sankar Mukherjee
#==================================================================================================================================

# Command line argumnt
todo=$1
controlmsrv=`echo $2 | tr [a-z] [A-Z]`
my_name=$3
run_as=$4

# Utility function
## Validate disk space
validation_disk_space(){
	set -x
	echo "[`date`] Starting validation."
	curnt_avl=`df -Pk ${my_home} | grep -v Available | awk '{ print $4 }'`
	if [ $curnt_avl -lt $min_space ]
        then
		echo "[`date`] ERROR - Current space required $min_space, while we have only $curnt_avl thus failed to continue."
		clear_fs
		exit 1
	fi
	curnt_avl=`df -Pk /var/tmp | grep -v Available | awk '{ print $4 }'`
        if [ $curnt_avl -lt 150000 ]
        then
                echo "[`date`] ERROR - Current space required for /var/tmp is 150MB, while we have only $curnt_avl thus failed to continue."
		clear_fs
                exit 1
        fi
        echo "[`date`] Space left is successfully validated."
}

## Clear unused data
clear_fs(){
	set -x
	echo "[`date`] Starting clearing."
	rm -f ${my_home}/DRKAI.*
	rm -f ${my_home}/PAKAI.*
        rm -f ${my_home}/setup.sh
        rm -rf ${my_home}/Setup_files
        rm -rf ${my_home}/FORMS
        rm -rf ${my_home}/EM
        rm -rf ${my_home}/Documentation
        rm -rf ${my_home}/CheckReq
	rm -rf /var/tmp/${my_name}_CTM_Upgrade
	sleep 60
	echo "[`date`] Completed clearing filesystem."
}

## Validate agent configuration
validation_agent_config(){
	set -x
	echo "[`date`] Starting validation."
	status_file=/tmp/ctmagent_config_chk.tmp.$$

	ls -ltr `which ag_diag_comm` >/dev/null 2>&1
        if [ $? -ne 0 ]
        then
                echo "[`date`] ERROR - Unable to find controlm status check  script."
                exit 1
        fi
	ag_diag_comm > ${status_file}

        tot_auth_stat=`grep "Authorized Servers Host Names" ${status_file} | awk -F":" '{ print $2 }' | awk -F":" '{ print NF  }'`
        srv_stat=`grep "Server Host Name" ${status_file} | awk -F":" '{ print $2 }' | tr [a-z] [A-Z] | grep -iq "$controlmsrv"; echo $?`
        auth_stat=`grep "Authorized Servers Host Names" ${status_file} | awk -F":" '{ print $2 }' | tr [a-z] [A-Z] | grep -iq "$controlmsrv"; echo $?`
	unx_png=`grep "Unix Ping to Server Platform" ${status_file} | awk -F":" '{ print $2 }' | grep -iq "Succeeded"; echo $?`
	agt_png=`grep "Agent Ping to Control-M" ${status_file} | awk -F":" '{ print $2 }' | grep -iq "Succeeded"; echo $?`

	if [ $tot_auth_stat -eq 1 -a $srv_stat -eq 0 -a $auth_stat -eq 0 -a $unx_png -eq 0 -a $agt_png -eq 0 ]
	then
		echo "[`date`] Current Agent configuration is successfully validated."
		rm -f ${status_file}
	else
		echo "[`date`] ERROR - Current Agent configuration is not in correct state."
		rm -f ${status_file}
                exit 1
	fi

	status_agent "STARTED"

	echo "[`date`] Agent validation completed."
}

## Find agent home
find_agent_home(){
        ls -ltr `which ag_diag_comm` >/dev/null 2>&1
        if [ $? -ne 0 ]
        then
                echo "[`date`] ERROR - Unable to find controlm status check  script."
                exit 1
        fi
	_agent_home=`ag_diag_comm | grep "Agent Directory" | awk -F":" '{ print $2 }' | xargs`
	dirname ${_agent_home}
}

## Backup current agent
backup_agent(){
	set -x

        clear_fs
	rm -f /var/tmp/ctm_bck_*
	rm -f /var/tmp/installed-versions.txt_*

        echo "[`date`] Generating backup environment."

	dtval=`date +%F-%H-%M`
	backup_file="ctm_bck_${dtval}.tar"
	backup_vrsn_file="installed-versions.txt_${dtval}.bck"
        err_log=/tmp/ctmagent.bckup.tmp.${dtval}.log
	echo "[`date`] Backup file name is ${backup_file} and version file name ${backup_vrsn_file}."

	find $agnt_home/ctm -type f ! -perm -u+w -exec chmod u+rw '{}' \; -print

	echo "[`date`] Starting backup process."

	cd ${agnt_home}
	tar -cvf "${backup_file}" "ctm" 2> ${err_log}
	tar_stat=$?

	if [ $tar_stat -ne 0 -a $tar_stat -ne 5 ]
	then
                echo "[`date`] Error status returned. Validating the error."
                echo "------------ERROR--------------"
		cat ${err_log}
                echo "-------------------------------"
                grep -iv "previous errors" ${err_log} | grep -v "Permission denied"
                if [ $? -eq 0 ] ; then
			echo "[`date`] ERROR - Couldnot complete backup of current agent. Archival process failed."
			rm -f ${err_log}
			clear_fs
			rm -f ${agnt_home}/${backup_file}
			exit 1
                else
			echo "[`date`] Found permission error. Thus skipping."
			rm -f ${err_log}
		fi
	fi
	if [ ! -f ${agnt_home}/${backup_file} ]
        then
                echo "[`date`] ERROR - Couldnot complete backup of current agent. Backup file cannot be found."
		clear_fs
                rm -f ${agnt_home}/${backup_file}
                exit 1
        fi

	mv ${agnt_home}/${backup_file} /var/tmp/${backup_file}
	if [ $? -ne 0  ]
	then
		echo "[`date`] ERROR - Couldnot complete backup of current agent. Archival process failed."
                clear_fs
		rm -f ${agnt_home}/${backup_file} /var/tmp/${backup_file}
		exit 1
	fi

	cp ${agnt_home}/installed-versions.txt /var/tmp/${backup_vrsn_file}
        if [ $? -ne 0 ]
        then
                echo "[`date`] ERROR - Couldnot complete backup of current agent. Version file backup issue."
                clear_fs
		rm -f /var/tmp/${backup_file} /var/tmp/${backup_vrsn_file}
                exit 1
        fi
 
	echo "[`date`] Completed backup."

}

## Download binary and validate checksum
download_content() {
	set -x
        echo "[`date`] Starting to download."
	file_to_download=$1
	file_actl_checksum=$2

        ls -ltr `which $download_exe` >/dev/null 2>&1
        if [ $? -ne 0 ]
        then
                echo "[`date`] ERROR - Unable to find downloader executale."
		clear_fs
                return 1
        fi

	if [ -f ${my_home}/${file_to_download} ]
	then
		echo "[`date`] File already present, thus not downloading. Detail: `ls -ltr ${my_home}/${file_to_download}`."
	else
		$download_exe "http://${bin_host}/${download_home}/${file_to_download}" -O "${my_home}/${file_to_download}"
		if [ $? -ne 0 ]
		then
			echo "[`date`] ERROR - Issue in downloading binary ${file_to_download}."
			clear_fs
			rm -f ${my_home}/${file_to_download}
			return 1
		fi
                if [ ! -f ${my_home}/${file_to_download} ]
                then
                        echo "[`date`] ERROR - Issue in downloading binary ${file_to_download}."
			clear_fs
                        rm -f ${my_home}/${file_to_download}
                        return 1
                fi
	fi
        echo "[`date`] Completed download."

        echo "[`date`] Checking checksum."
	checksum_stat=`cksum ${my_home}/${file_to_download} | awk '{ print $1 }' | grep -q "${file_actl_checksum}"; echo $?`
	if [ $checksum_stat -ne 0 ]
        then
		echo "[`date`] ERROR - Issue in downloading binary, checksum doesnot match."
		clear_fs
                rm -f ${my_home}/${file_to_download}
		return 1
	fi
        echo "[`date`] Completed checksum validation."
	return 0
}

## Agent Upgrade to new version
agent_upgrade(){
	set -x
        echo "[`date`] Initiating upgrade prechecks."

	clear_fs

	download_content "${upgrade_bin}" "${upgrade_bin_hsh}"
        if [ $? -ne 0 ] ; then
                echo "[`date`] ERROR - Exiting programe."
                exit 1
        fi
        download_content "${upgrade_optn_fl}" "${upgrade_optn_fl_hsh}"
        if [ $? -ne 0 ] ; then
                echo "[`date`] ERROR - Exiting programe."
                exit 1
        fi
	if [ ! -f ${my_home}/${upgrade_bin} -o ! -f ${my_home}/${upgrade_optn_fl} ]
	then
		echo "[`date`] ERROR - Required files not present for upgrade to be initiated."
		clear_fs
		exit 1
	fi

	echo "[`date`] Uncompressing the binary."
	cd ${my_home}
	tar -xvf ${upgrade_bin}
	if [ $? -ne 0 ] 
	then
		echo "[`date`] ERROR - Uncompression failed."
		clear_fs
		exit 1
	fi
	if [ ! -f ${my_home}/setup.sh -o ! -d ${my_home}/Setup_files ]
        then
                echo "[`date`] ERROR - Few content missing after Uncompression."
		clear_fs
                exit 1
        fi
	rm -f ${my_home}/${upgrade_bin}
	sleep 60

        scrpt_perm=`chmod a+x ${my_home}/setup.sh ; echo $?`
        bin_hom_perm=`chmod -R a+x ${my_home}/Setup_files ; echo $?`
        if [ $scrpt_perm -ne 0 -o $bin_hom_perm -ne 0 ]
        then
                echo "[`date`] ERROR - Unable to set correct permission to expanded binary."
		clear_fs
                exit 1
        fi

	[ ! -d /var/tmp/${my_name}_CTM_Upgrade ] && mkdir /var/tmp/${my_name}_CTM_Upgrade
        if [ $? -ne 0 ]
        then
                echo "[`date`] ERROR - Setup File backup location creation failed."
		clear_fs
                exit 1
        fi
        mv ${my_home}/Setup_files /var/tmp/${my_name}_CTM_Upgrade
        if [ $? -ne 0 ]
        then
                echo "[`date`] ERROR - Moving Setup File to backup location failed."
		clear_fs
                exit 1
        fi
        ln -s /var/tmp/${my_name}_CTM_Upgrade/Setup_files ${my_home}/Setup_files
        if [ $? -ne 0 ]
        then
                echo "[`date`] ERROR - Issue in creating Setup File Link to ${my_home}."
		clear_fs
                exit 1
        fi

	echo "[`date`] Successful Uncompression."

	validation_disk_space

	echo "[`date`] Starting to execute upgrade."
	status_install=0
	dtval=`date +%F-%H-%M`
	upgd_cmmd_file=/tmp/ctmagent_upgrade_${dtval}_cmd.tmp.$$
	${my_home}/setup.sh -silent ${my_home}/upgrade.xml > ${upgd_cmmd_file} 2>&1

	if [ $? -ne 0 ]
        then
                echo "[`date`] ERROR - Upgradation failed."
                status_install=1
        fi
	grep -i "completed successfully" ${upgd_cmmd_file} | grep -i "installation"
        if [ $? -ne 0 ]
        then
                echo "[`date`] ERROR - Upgradation failed. Not stated completion in logs."
                status_install=1
        fi

	if [ $status_install -ne 0 ]
        then
		echo "[`date`] ERROR - Upgradation failed. Retry in progress."
		dtval=`date +%F-%H-%M`
		upgd_cmmd_file=/tmp/ctmagent_upgrade_${dtval}_cmd.tmp.$$
		${my_home}/setup.sh -silent ${my_home}/upgrade.xml > ${upgd_cmmd_file} 2>&1
		
		if [ $? -ne 0 ]
		then
			echo "[`date`] ERROR - Retry upgradation failed."
			clear_fs
			exit 1
		fi
		grep -i "completed successfully" ${upgd_cmmd_file} | grep -i "installation"
		if [ $? -ne 0 ]
		then
			echo "[`date`] ERROR - Retry failed. Not stated completion in logs."
			clear_fs
			exit 1
		fi
	fi

	ag_diag_comm | grep "Agent Version" | grep "${upgrade_final_verion}"
        if [ $? -ne 0 ]
        then
                echo "[`date`] ERROR - Upgradation failed. Not showing correct version in status command."
		clear_fs
                exit 1
        fi
	echo "[`date`] Successfully validated agent upgrade."

	echo "---------UPGRADE LOG---------"
	cat ${upgd_cmmd_file}
	echo "-----------------------------"
	rm -f ${upgd_cmmd_file}
	clear_fs

        echo "___UPGRADE SUCCESSFUL___"
}

## Agent Patching
agent_patch(){
	set -x
        echo "[`date`] Starting patch prechecks."

        clear_fs

	download_content "${patch_bin}" "${patch_bin_hsh}"
        if [ $? -ne 0 ] ; then
                echo "[`date`] ERROR - Exiting programe."
                exit 1
        fi
        if [ ! -f ${my_home}/${patch_bin} ]
        then
                echo "[`date`] ERROR - Required files not present for patch to be initiated."
		clear_fs
                exit 1
        fi
	chmod a+x ${my_home}/${patch_bin}
        if [ $? -ne 0 ]
        then
                echo "[`date`] ERROR - Unable to make binary executable."
		clear_fs
                exit 1
        fi
	
	validation_disk_space

        echo "[`date`] Starting to execute patch."
	dtval=`date +%F-%H-%M`
        pch_cmmd_file=/tmp/ctmagent_patch_${dtval}_cmd.tmp.$$
	${my_home}/${patch_bin} -s > ${pch_cmmd_file} 2>&1        

        if [ $? -ne 0 ]
        then
                echo "[`date`] ERROR - Upgradation failed."
		clear_fs
                exit 1
        fi
        grep -i "completed successfully" ${pch_cmmd_file} | grep -i "installation"
        if [ $? -ne 0 ]
        then
                echo "[`date`] ERROR - Patching failed. Not stated completion in logs."
		clear_fs
                exit 1
        fi
        ag_diag_comm | grep "Agent Version" | grep "${patch_final_verion}"
        if [ $? -ne 0 ]
        then
                echo "[`date`] ERROR - Patch failed. Not showing correct version in status command."
		clear_fs
                exit 1
        fi
	echo "[`date`] Successfully validated agent patch."

        echo "---------PATCH LOG---------"
        cat ${pch_cmmd_file}
        echo "-----------------------------"
        rm -f ${pch_cmmd_file}
	clear_fs

        echo "___PATCH SUCCESSFUL___"
}

## Protocol Version Update
update_proto() {
        set -x
        echo "[`date`] Starting Protocol Version Upgrade."

        ls -ltr `which ctmagcfg` >/dev/null 2>&1
        if [ $? -ne 0 ]
        then
                echo "[`date`] ERROR - Unable to find controlm configuration script."
                exit 1
        fi

        ls -ltr `which ag_diag_comm` >/dev/null 2>&1
        if [ $? -ne 0 ]
        then
                echo "[`date`] ERROR - Unable to find controlm status check script."
                exit 1
        fi

        status_agent "STOPPED"

        proto_file=/tmp/ctmagent_proto_file.tmp.$$
        echo "7" > ${proto_file}
        echo "9" >> ${proto_file}
        echo "${protocol_version}" >> ${proto_file}
        echo "r" >> ${proto_file}
        echo "s" >> ${proto_file}
        echo "q" >> ${proto_file}
        echo "" >> ${proto_file}

        ctmagcfg < ${proto_file}
        if [ $? -ne 0 ]
        then
                echo "[`date`] ERROR - Failed to set correct protocol version."
                rm -f ${proto_file}
                exit 1
        fi

        echo "[`date`] Current protocol version: "
        ag_diag_comm | grep "Server-Agent Protocol Version" | grep "${protocol_version}"

        if [ $? -ne 0 ]
        then
                echo "[`date`] ERROR - Failed to set correct protocol version."
                rm -f ${proto_file}
                exit 1
        fi

        rm -f ${proto_file}

        echo "[`date`] Completed Protocol Version Upgrade completed."
}



## Rollback 
rollback_agent(){
	set -x
	echo "[`date`] Initiating agent upgrade rollback."
	
        clear_fs
	
	cd /var/tmp
	backup_fl=`ls -ltr ctm_bck_*tar | tail -1 | awk '{ print $9 }'`
	backup_vrsn=`echo $backup_fl | awk -F"_bck_" '{ print $2 }' | awk -F"." '{ print $1 }'`
	backup_vrsn_file="installed-versions.txt_${backup_vrsn}.bck"
        if [ ! -f /var/tmp/${backup_fl} -o ! -f /var/tmp/${backup_vrsn_file} ]
        then
                echo "[`date`] ERROR - Backup files not present. Rollback unsuccessfull."
		exit 1
	fi
	
        mv /var/tmp/${backup_fl} ${agnt_home}/${backup_fl}
        if [ $? -ne 0 ]
        then
                echo "[`date`] ERROR - Couldnot complete rollback. Could not restore backup file."
                exit 1
        fi

	echo "[`date`] File to rollback ${backup_fl} and backup version file ${backup_vrsn_file}."

	find $agnt_home/ctm -type f ! -perm -u+w -exec chmod u+rw '{}' \; -print

	cd ${agnt_home}
	tar -xvf ${backup_fl}
	unzip_stat=$?
        if [ $unzip_stat -ne 0 -a $unzip_stat -ne 5 ]
        then
                echo "[`date`] ERROR - Couldnot complete rollback. Unarchival failed."
                exit 1
        fi

	mv /var/tmp/${backup_vrsn_file} ${agnt_home}/installed-versions.txt
        if [ $? -ne 0 ] 
        then
                echo "[`date`] ERROR - Couldnot complete rollback. Could not restore version file."
                exit 1
        fi
	echo "[`date`] Restoration completed."

	start_agent

	echo "___ROLLBACK SUCCESSFUL___"
}

## Agent status check
status_agent(){
	set -x
	state_now=$1
        echo "[`date`] Starting status check for status $state_now."

	ls -ltr `which ag_diag_comm` >/dev/null 2>&1
	if [ $? -ne 0 ]
        then
		echo "[`date`] ERROR - Unable to find controlm status check  script."
                exit 1
	fi

        status_file=/tmp/ctmagent_stat_chk.tmp.$$
	ag_diag_comm > ${status_file} 2>&1

	if [ `echo ${state_now} | grep -q STARTED ; echo $?` -eq 0 ] 
	then
		agt_lst=`grep "Agent Listener" ${status_file} | grep -q "Running as"; echo $?`
                agt_tck=`grep "Agent Tracker " ${status_file} | grep -q "Running as"; echo $?`
		if [ $agt_lst -eq 0 -a $agt_tck -eq 0 ] ; then
			echo "[`date`] Successfully validated controlm status."
		else
			echo "[`date`] ERROR - Agent not successfully running."
			rm -f ${status_file}
			exit 1
		fi
	elif [ `echo ${state_now} | grep -q STOPPED ; echo $?` -eq 0 ]
        then
                agt_lst=`grep "Agent Listener" ${status_file} | grep -q "Not running"; echo $?`
                agt_tck=`grep "Agent Tracker " ${status_file} | grep -q "Not running"; echo $?`
                if [ $agt_lst -eq 0 -a $agt_tck -eq 0 ] ; then
                        echo "[`date`] Successfully validated controlm status."
                else
                        echo "[`date`] ERROR - Agent not successfully stopped."
			rm -f ${status_file}
                        exit 1
                fi
	else
		echo "[`date`] ERROR - Unable to validate controlm status."
		rm -f ${status_file}
		exit 1
	fi

	rm -f ${status_file}
        echo "[`date`] Ending validation of status."
}

## Check is agent is started
is_started(){
	set -x
	echo "[`date`] Starting to check is agent is in started state."
	status_agent "STARTED"
	echo "[`date`] Succefully validated agent is in started state."
}

## Agent startup
start_agent(){
	set -x
        echo "[`date`] Starting to startup agent."

	ls -ltr `which start-ag` >/dev/null 2>&1
        if [ $? -ne 0 ]
        then
                echo "[`date`] ERROR - Unable to find controlm shutdown script."
                exit 1
        fi

	status_agent "STOPPED"

        promt_file=/tmp/ctmagent_promt_file.tmp.$$
        echo "${my_name}" > $promt_file
        echo "ALL" >> $promt_file
        echo "" >> $promt_file

	if [ `echo ${run_as} | grep -qi root ; echo $?` -eq 0 ]
	then
                sudo start-ag < $promt_file
                if [ $? -ne 0 ]
                then
                        dzdo start-ag < $promt_file
                fi
        else
                start-ag < $promt_file
	fi
        rm -f $promt_file

	sleep 5

        status_agent "STARTED"

        echo "[`date`] Successfully started agent."
}

## Agent stop
stop_agent(){
	set -x
        echo "[`date`] Starting to stop agent."

	ls -ltr `which shut-ag` >/dev/null 2>&1
	if [ $? -ne 0 ]
	then
		echo "[`date`] ERROR - Unable to find controlm shutdown script."
		exit 1
	fi

	status_agent "STARTED"

        promt_file=/tmp/ctmagent_promt_file.tmp.$$
        echo "${my_name}" > $promt_file
        echo "ALL" >> $promt_file
        echo "" >> $promt_file

	if [ `echo ${run_as} | grep -qi root ; echo $?` -eq 0 ]
	then
                sudo shut-ag < $promt_file
                if [ $? -ne 0 ]
                then
                        dzdo shut-ag < $promt_file
                fi
        else
                shut-ag < $promt_file
	fi

        rm -f $promt_file

	sleep 5

	status_agent "STOPPED"

        echo "[`date`] Successfully stopped agent."
}

## Module Backup
backup_module() {
	set -x

	mod_name=$1

        clear_fs
	rm -f /var/tmp/ctm_cm_${mod_name}_bck_*
        rm -f /var/tmp/installed-versions_cm_${mod_name}_*

        echo "[`date`] Generating backup for module ${mod_name}."
	
	dtval=`date +%F-%H-%M`
	backup_file="ctm_cm_${mod_name}_bck_${dtval}.tar"
	backup_vrsn_file="installed-versions_cm_${mod_name}_${dtval}.bck"
	err_log=/tmp/ctmagent.mod.${mod_name}.tmp.${dtval}.log
	echo "[`date`] Backup module file name is ${backup_file} and version file name ${backup_vrsn_file}."

	echo "[`date`] Starting backup process."

	cd ${agnt_home}/ctm/cm

	tar -cvf "${backup_file}" "${mod_name}" 2> ${err_log}
	tar_stat=$?

	if [ $tar_stat -ne 0 -a $tar_stat -ne 5 ]
	then
		echo "[`date`] ERROR - Error status returned. Validating the error."
                echo "------------ERROR--------------"
		cat ${err_log}
		echo "-------------------------------"
		grep -iv "previous errors" ${err_log} | grep -v "Permission denied"
		if [ $? -eq 0 ] ; then
			echo "[`date`] ERROR - Couldnot complete backup of current agent's module ${mod_name}. Archival process failed."
			rm -f ${err_log}
			rm -f ${agnt_home}/ctm/cm/${backup_file}
			return 1
		else
			echo "[`date`] Found permission error. Thus skipping."
			rm -f ${err_log}
		fi
	fi

	if [ ! -f ${agnt_home}/ctm/cm/${backup_file} ]
        then
                echo "[`date`] ERROR - Couldnot complete backup of current agent modules. Backup file cannot be found."
                rm -f ${agnt_home}/ctm/cm/${backup_file}
                return 1
        fi

	mv ${agnt_home}/ctm/cm/${backup_file} /var/tmp/${backup_file}
	if [ $? -ne 0  ]
	then
		echo "[`date`] ERROR - Couldnot complete backup of current agent modules. Archival process failed."
		rm -f ${agnt_home}/ctm/cm/${backup_file} /var/tmp/${backup_file}
		return 1
	fi

	cp ${agnt_home}/installed-versions.txt /var/tmp/${backup_vrsn_file}
        if [ $? -ne 0 ]
        then
                echo "[`date`] ERROR - Couldnot complete backup of current agent. Version file backup issue."
		rm -f /var/tmp/${backup_file} /var/tmp/${backup_vrsn_file}
                return 1
        fi
 
	echo "[`date`] Completed backup."
	return 0

}

## Module Upgrade
upgrade_module() {
	set -x
        echo "[`date`] Initiating module upgrade prechecks."

        if [ -f ${my_home}/installed-versions.txt ] ; then
	        vsn_fl=${agnt_home}/installed-versions.txt
        elif [ -f ${agnt_home}/installed-versions.txt ] ; then
        	vsn_fl=${my_home}/installed-versions.txt
        else
        	echo "[`date`] ERROR - Unable to locate version file."
        	exit 1
        fi

        clear_fs
        module_final_status=0
	
	stop_agent

	cd ${agnt_home}/ctm/cm
	for mod_nm in `ls -ltr | grep -v uninstall | grep ^d | awk '{ print $9 }' | grep "^[A-Z]"`
	do
		echo "[`date`] Starting to work on module ${mod_nm}."
		mod_no=1
		mod_ok=1
                grep -q ^${mod_nm} $module_file
		if [ $? -ne 0 ] 
		then
			mod_no=0
		else
			tar_vrsn=`grep ^${mod_nm} $module_file | awk -F"," '{ print $2 }'`
			case ${mod_nm} in
			"SAP")
			grep "SAP" ${vsn_fl} | awk '{ print $5 }' | awk -F"." '{ print $1 }' | grep -v ${tar_vrsn}
			if [ $? -eq 0 ] 
			then
				grep "SAP" ${vsn_fl}
				mod_ok=0 
			fi
			;;
			"AFT")
                        grep "Advanced File Transfer" ${vsn_fl} | awk '{ print $5 }' | awk -F"." '{ print $1 }' | grep -v ${tar_vrsn}
                        if [ $? -eq 0 ]
                        then
                                grep "Advanced File Transfer" ${vsn_fl}
                                mod_ok=0
                        fi
			;;
                        "HADOOP")
                        grep "Hadoop" ${vsn_fl} | awk '{ print $5 }' | awk -F"." '{ print $1 }' | grep -v ${tar_vrsn}
                        if [ $? -eq 0 ]
                        then
                                grep "Hadoop" ${vsn_fl}
                                mod_ok=0
                        fi
                        ;;
                        "INF")
                        grep "Informatica" ${vsn_fl} | awk '{ print $5 }' | awk -F"." '{ print $1 }' | grep -v ${tar_vrsn}
                        if [ $? -eq 0 ]
                        then
                                grep "Informatica" ${vsn_fl}
                                mod_ok=0
                        fi
                        ;;
			esac
		fi
		if [ $mod_no -eq 0 ]
		then
			echo "[`date`] Module ${mod_nm} cannot be handles, but will be reported."
			[ $module_final_status -ne 1 ] && module_final_status=2
                elif [ $mod_ok -eq 0 ]
                then
                        echo "[`date`] Module ${mod_nm} not in version to apply upgrade."
		else
			mupgd_bin=`grep ^${mod_nm} $module_file | awk -F"," '{ print $3 }'`
			mupgd_bin_hsh=`grep ^${mod_nm} $module_file | awk -F"," '{ print $4 }'`
			mupgd_ctl_fl=`grep ^${mod_nm} $module_file | awk -F"," '{ print $5 }'`
                        mupgd_ctl_fl_hsh=`grep ^${mod_nm} $module_file | awk -F"," '{ print $6 }'`
                        clear_fs

			backup_module ${mod_nm}
                        if [ $? -ne 0 ] ; then
                                echo "[`date`] ERROR - Backup failed for module ${mod_nm}, will continue with next module."
                                module_final_status=1
                                continue
                        fi

                        download_content "${mupgd_bin}" "${mupgd_bin_hsh}"
                        download_content "${mupgd_ctl_fl}" "${mupgd_ctl_fl_hsh}"
			if [ ! -f ${my_home}/${mupgd_bin} -o ! -f ${my_home}/${mupgd_ctl_fl} ]
			then
				echo "[`date`] ERROR - Required files not present for upgrade to be initiated."
				clear_fs
				rm -f ${my_home}/${mupgd_bin} 
				rm -f ${my_home}/${mupgd_ctl_fl}
				module_final_status=1
				continue
			fi

			cd ${my_home}
			tar -xvf ${mupgd_bin}
			if [ $? -ne 0 ] 
			then
				echo "[`date`] ERROR - Uncompression failed."
				clear_fs
				rm -f ${my_home}/${mupgd_bin}
                                rm -f ${my_home}/${mupgd_ctl_fl}
				module_final_status=1
                                continue
			fi
			if [ ! -f ${my_home}/setup.sh -o ! -d ${my_home}/Setup_files ]
		        then
                		echo "[`date`] ERROR - Few content missing after Uncompression."
                                clear_fs
                                rm -f ${my_home}/${mupgd_bin}
                                rm -f ${my_home}/${mupgd_ctl_fl}
		                module_final_status=1
                                continue
		        fi

			rm -f ${my_home}/${mupgd_bin}
			sleep 30
		        mscrpt_perm=`chmod a+x ${my_home}/setup.sh ; echo $?`
		        mbin_hom_perm=`chmod -R a+x ${my_home}/Setup_files ; echo $?`
		        if [ $mscrpt_perm -ne 0 -o $mbin_hom_perm -ne 0 ]
		        then
                		echo "[`date`] ERROR - Unable to set correct permission to expanded binary."
                                clear_fs
                                rm -f ${my_home}/${mupgd_ctl_fl}
		                module_final_status=1
                                continue
		        fi

			[ ! -d /var/tmp/${my_name}_CTM_Upgrade ] && mkdir /var/tmp/${my_name}_CTM_Upgrade
		        if [ $? -ne 0 ]
        		then
                		echo "[`date`] ERROR - Moving Setup File to backup location failed."
		                clear_fs
                                rm -f ${my_home}/${mupgd_ctl_fl}
                		module_final_status=1
                                continue
		        fi
		        ln -s /var/tmp/${my_name}_CTM_Upgrade/Setup_files ${my_home}/Setup_files
		        if [ $? -ne 0 ]
		        then
                		echo "[`date`] ERROR - Issue in creating Setup File Link to ${my_home}."
		                clear_fs
                                rm -f ${my_home}/${mupgd_ctl_fl}
                		module_final_status=1
                                continue
		        fi
			
			echo "[`date`] Successful Uncompression."
			validation_disk_space

			mdtval=`date +%F-%H-%M`
			mupgd_cmmd_file=/tmp/ctmagent_upgrade_module_${mod_nm}_${mdtval}_cmd.tmp.$$

			${my_home}/setup.sh -silent ${my_home}/${mupgd_ctl_fl} > ${mupgd_cmmd_file} 2>&1
			if [ $? -ne 0 ]
			then
				echo "[`date`] ERROR - Module ${mod_nm} upgradation failed."
                                clear_fs
                                rm -f ${my_home}/${mupgd_ctl_fl}
				module_final_status=1
                                continue
			fi
			
			echo "---------MODULE (${mod_nm}) UPGRADE LOG---------"
			cat ${mupgd_cmmd_file}
			echo "------------------------------------------------"
			clear_fs
                        rm -f ${mupgd_cmmd_file}
			rm -f ${my_home}/${mupgd_ctl_fl}
			
			echo "[`date`] Successfully completed module upgrade."

                        mdo_patch=`grep ^${mod_nm} $module_file | awk -F"," '{ print $7 }'`
			
			if [ $mdo_patch -eq 0 ] ; then
				echo "[`date`] Starting module patch."
	                        mpatch_bin=`grep ^${mod_nm} $module_file | awk -F"," '{ print $8 }'`
        	                mpatch_bin_hsh=`grep ^${mod_nm} $module_file | awk -F"," '{ print $9 }'`
			
				download_content "${mpatch_bin}" "${mpatch_bin_hsh}"	
				if [ ! -f ${my_home}/${mpatch_bin} ]
			        then
			                echo "[`date`] ERROR - Required files not present for patch to be initiated."
	                                clear_fs
			                module_final_status=1
					continue
			        fi
				chmod a+x ${my_home}/${mpatch_bin}
				mdtval=`date +%F-%H-%M`
			        mpch_cmmd_file=/tmp/ctmagent_patch_module_${mod_nm}_${mdtval}_cmd.tmp.$$
				${my_home}/${mpatch_bin} -s > ${mpch_cmmd_file} 2>&1
				if [ $? -ne 0 ]
			        then
			                echo "[`date`] ERROR - Module ${mod_nm} patching failed."
					clear_fs
					rm -f ${my_home}/${mpatch_bin}
                                        module_final_status=1
                                        continue
			        fi
			        echo "---------MODULE (${mod_nm}) PATCH LOG---------"
			        cat ${mpch_cmmd_file}
			        echo "----------------------------------------------"
			        rm -f ${mpch_cmmd_file}
                                rm -f ${my_home}/${mpatch_bin}
				clear_fs
				echo "[`date`] Successfully completed module patching."
			fi
		fi
	done
	
	echo "[`date`] Completed module upgrade process."	

	start_agent

	exit ${module_final_status} 

}


# ___MAIN___

## Environment setup
bin_host=@@@BINARY_HOST@@@
upgrade_bin=@@@UPGRADE_BINARY@@@
upgrade_bin_hsh=@@@UPGRADE_BINARY_HASH@@@
do_patch=@@@IS_PATCH_REQUIRE@@@
patch_bin=@@@PATCH_BINARY@@@
patch_bin_hsh=@@@PATCH_BINARY_HASH@@@
upgrade_optn_fl=upgrade.xml
upgrade_optn_fl_hsh=@@@OPTION_FILE_HASH@@@
do_proto_update=@@@IS_PROTOCOL_UPGRADE_REQUIRE@@@
protocol_version=@@@FINAL_PROTOCOL_VERSION@@@
do_module_update=@@@IS_MODULE_UPGRADE_REQUIRE@@@
## Module definitions
module_file=/tmp/upgrade_module_file.tmp.$$
do_module_aft=@@@IS_AFT_UPGRADE_REQUIRE@@@
do_module_sap=@@@IS_SAP_UPGRADE_REQUIRE@@@
do_module_informatica=@@@IS_INFORMATICA_UPGRADE_REQUIRE@@@
do_module_hadoop=@@@IS_HADOOP_UPGRADE_REQUIRE@@@
if [ $do_module_aft -eq 0 ]
then
	echo "AFT,@@@AFT_CURRENT_VERSION@@@,@@@AFT_UPGRADE_BINARY@@@,@@@AFT_UPGRADE_BINARY_HASH@@@,@@@AFT_UPGRADE_CONTRL_FILE@@@,@@@AFT_UPGRADE_CONTRL_HASH@@@,@@@AFT_PATCH_IS@@@,@@@AFT_PATCH_BINARY@@@,@@@AFT_PATCH_BINARY_HASH@@@" >> $module_file
fi
if [ $do_module_sap -eq 0 ]
then
	echo "SAP,@@@SAP_CURRENT_VERSION@@@,@@@SAP_UPGRADE_BINARY@@@,@@@SAP_UPGRADE_BINARY_HASH@@@,@@@SAP_UPGRADE_CONTRL_FILE@@@,@@@SAP_UPGRADE_CONTRL_HASH@@@,@@@SAP_PATCH_IS@@@,@@@SAP_PATCH_BINARY@@@,@@@SAP_PATCH_BINARY_HASH@@@" >> $module_file
fi
if [ $do_module_informatica -eq 0 ]
then
        echo "INF,@@@INFORMATICA_CURRENT_VERSION@@@,@@@INFORMATICA_UPGRADE_BINARY@@@,@@@INFORMATICA_UPGRADE_BINARY_HASH@@@,@@@INFORMATICA_UPGRADE_CONTRL_FILE@@@,@@@INFORMATICA_UPGRADE_CONTRL_HASH@@@,@@@INFORMATICA_PATCH_IS@@@,@@@INFORMATICA_PATCH_BINARY@@@,@@@INFORMATICA_PATCH_BINARY_HASH@@@" >> $module_file
fi
if [ $do_module_hadoop -eq 0 ]
then
        echo "HADOOP,@@@HADOOP_CURRENT_VERSION@@@,@@@HADOOP_UPGRADE_BINARY@@@,@@@HADOOP_UPGRADE_BINARY_HASH@@@,@@@HADOOP_UPGRADE_CONTRL_FILE@@@,@@@HADOOP_UPGRADE_CONTRL_HASH@@@,@@@HADOOP_PATCH_IS@@@,@@@HADOOP_PATCH_BINARY@@@,@@@HADOOP_PATCH_BINARY_HASH@@@" >> $module_file
fi

download_home="ctmagent/@@@BINARY_HOME@@@/linux"

upgrade_final_verion=@@@UPGRADE_VERSION@@@
patch_final_verion=@@@PATCH_VERSION@@@

my_home=`echo $HOME`
min_space=@@@MINIMUM_FS_SPACE@@@
download_exe=wget
agnt_home=`find_agent_home`

if [ ! -d ${agnt_home}/ctm ]
then
	echo "[`date`] ERROR - Cannot find ControlM agent home."
	exit 1
fi 
echo "[`date`] Identified ControlM agent home as ${agnt_home}/ctm."

case ${todo} in 
	upgrade_agent)
		echo "[`date`] Requested ControlM agent upgrade."
		# Validating agent
		validation_agent_config
		# Initiating backup
		backup_agent
		# Shutting down agent
		stop_agent	
		# Updating agent
		agent_upgrade
		# Patch agent
		[ $do_patch -eq 0 ] && agent_patch
                # Update Agent Protocol Version
                [ $do_proto_update -eq 0 ] && update_proto
		# Starting up agent
		start_agent
		;;
	rollback_agent)
                echo "[`date`] Requested ControlM agent upgrade rollback."
                # Rollback agent upgrade
		rollback_agent
                ;;
        backup_agent)
                echo "[`date`] Requested ControlM agent to be backed up."
                # Initiating backup
                backup_agent
                ;;
        upgrade_module)
                echo "[`date`] Requested ControlM agent agent to be upgrade."
		if [ $do_module_update -eq 0 ]
		then
                	# Updating module
	                upgrade_module
		fi
                ;;
	start_agent)
                echo "[`date`] Start ControlM agent."
		# Starting up agent
		start_agent
                ;;
	stop_agent)
                echo "[`date`] Stop ControlM agent."
		# Shutting down agent
                stop_agent
                ;;
        is_started)
                echo "[`date`] Check if ControlM agent is running."
	        # Check status
        	is_started
		;;
	*)
                echo "[`date`] Error unknown action requested to perform."
		exit 1
esac
