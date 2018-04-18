#!/bin/bash 
#==================================================================================================================================
# Usage  : Script to install patch and maintain ControlM Upgrade Tool
# Version: 1.2 - Module Upgrade Option
#          1.1 - Initial Stable Version
# Date   : 16-04-2018
# Author : Sankar Mukherjee
#==================================================================================================================================
script_home=$(cd $(dirname $0);pwd)
echo "======================================================================================="
echo "============================= ControlM Agent Upgrade Tool ============================="
echo "======================================================================================="
echo ""

echo "Please provide the answer for the following question to create a new upgrade utility."
echo ""

read -p "Please provide the contact email id for admin: " email_id
read -p "Please provide the expected minumum space required for this upgrade: " fs_req
read -p "Please provide the user to connect to agent hosts: " ctm_user
read -p "Please provide the user's password to connect to agent hosts: " ctm_usr_passwd
read -p "Please provide the current version: " cur_vern
read -p "Please provide the upgraded version id(This string will be searched in version to validate upgradation): " upgrad_id
read -p "Please provide the HP Unix Upgrade binary location(Should be uploaded in this host): " upgd_bin_hp
[ ! -f $upgd_bin_hp ] && ( echo "ERROR: Binary not accessable."; exit 1 )
read -p "Please provide the Linux(x86_64) Upgrade binary location(Should be uploaded in this host): " upgd_bin_lnx
[ ! -f $upgd_bin_lnx ] && ( echo "ERROR: Binary not accessable."; exit 1 )
read -p "Please provide the AIX Upgrade binary location(Should be uploaded in this host): " upgd_bin_aix
[ ! -f $upgd_bin_aix ] && ( echo "ERROR: Binary not accessable."; exit 1 )
read -p "Please provide the silent install option file: " optn_file
[ ! -f $optn_file ] && ( echo "ERROR: Option file not accessable."; exit 1 )
upgd_bin_hp_hash=$(cksum $upgd_bin_hp | awk '{ print $1 }')
upgd_bin_lnx_hash=$(cksum $upgd_bin_lnx | awk '{ print $1 }')
upgd_bin_aix_hash=$(cksum $upgd_bin_aix | awk '{ print $1 }')
optn_file_hash=$(cksum $optn_file | awk '{ print $1 }')
read -p "Do you want to upgrade Agent protocol version(Y/n): " is_proto
if [ "$is_proto" == "Y" -o "$is_proto" == "y" ] ; then
	is_proto_value=0
	read -p "Please provide the protocol version to set after upgrade: " final_proto_ver
else
	is_proto_value=1
fi
read -p "Do you want to patch after upgrade(Y/n): " is_patch
if [ "$is_patch" == "Y" -o "$is_patch" == "y" ] ; then
	read -p "Please provide the HP Unix patch binary location(Should be uploaded in this host): " patch_bin_hp
	[ ! -f $patch_bin_hp ] && ( echo "ERROR: Binary not accessable."; exit 1 )
	patch_bin_hp_hash=$(cksum $patch_bin_hp | awk '{ print $1 }')
        read -p "Please provide the Linux(x86_64) patch binary location(Should be uploaded in this host): " patch_bin_lnx
        [ ! -f $patch_bin_lnx ] && ( echo "ERROR: Binary not accessable."; exit 1 )
        patch_bin_lnx_hash=$(cksum $patch_bin_lnx | awk '{ print $1 }')
        read -p "Please provide the AIX patch binary location(Should be uploaded in this host): " patch_bin_aix
        [ ! -f $patch_bin_aix ] && ( echo "ERROR: Binary not accessable."; exit 1 )
        patch_bin_aix_hash=$(cksum $patch_bin_aix | awk '{ print $1 }')
	read -p "Please provide the patch version id(This string will be searched in version to validate patching): " patch_id
	activity_id="V${upgrad_id}P${patch_id}U${ctm_user}"
else
	activity_id="V${upgrad_id}U${ctm_user}"
fi

read -p "Do you want to upgrade modile(Y/n): " is_module
if [ "$is_module" == "Y" -o "$is_module" == "y" ] ; then
	is_module=0
	read -p "Do you want to upgrade AFT (Y/n): " do_aft
	if [ "$do_aft" == "Y" -o "$do_aft" == "y" ] ; then
		do_aft=0
                read -p "Please provide the current version to initiate upgrade: " cur_versn_aft
		read -p "Please provide the HP Unix module upgrade binary location(Should be uploaded in this host): " upgd_bin_hp_aft
		[ ! -f $upgd_bin_hp_aft ] && ( echo "ERROR: Binary not accessable."; exit 1 )
                upgd_bin_hash_hp_aft=$(cksum $upgd_bin_hp_aft | awk '{ print $1 }')
                read -p "Please provide the Linux(x86_64) module upgrade binary location(Should be uploaded in this host): " upgd_bin_linux_aft
                [ ! -f $upgd_bin_linux_aft ] && ( echo "ERROR: Binary not accessable."; exit 1 )
                upgd_bin_hash_linux_aft=$(cksum $upgd_bin_linux_aft | awk '{ print $1 }')
                read -p "Please provide the AIX module upgrade binary location(Should be uploaded in this host): " upgd_bin_aix_aft
		[ ! -f $upgd_bin_aix_aft ] && ( echo "ERROR: Binary not accessable."; exit 1 )
                upgd_bin_hash_aix_aft=$(cksum $upgd_bin_aix_aft | awk '{ print $1 }')
		read -p "Please provide the silent install option file: " optn_file_aft
		[ ! -f $optn_file_aft ] && ( echo "ERROR: File not accessable."; exit 1 )
		optn_file_hash_aft=$(cksum $optn_file_aft | awk '{ print $1 }')
		read -p "Do you want to patch AFT (Y/n): " is_patch_aft
                if [ "$is_patch_aft" == "Y" -o "$is_patch_aft" == "y" ] ; then
			is_patch_aft=0
			read -p "Please provide the HP Unix patch binary location for AFT(Should be uploaded in this host): " patch_bin_hp_aft
                        [ ! -f $patch_bin_hp_aft ] && ( echo "ERROR: Binary not accessable."; exit 1 )
			patch_bin_hash_hp_aft=$(cksum $patch_bin_hp_aft | awk '{ print $1 }')
                        read -p "Please provide the Linux(x86_64) patch binary location for AFT(Should be uploaded in this host): " patch_bin_linux_aft
                        [ ! -f $patch_bin_linux_aft ] && ( echo "ERROR: Binary not accessable."; exit 1 )
                        patch_bin_hash_linux_aft=$(cksum $patch_bin_linux_aft | awk '{ print $1 }')
			read -p "Please provide the AIX patch binary location for AFT(Should be uploaded in this host): " patch_bin_aix_aft
                        [ ! -f $patch_bin_aix_aft ] && ( echo "ERROR: Binary not accessable."; exit 1 )
                        patch_bin_hash_aix_aft=$(cksum $patch_bin_aix_aft | awk '{ print $1 }')
		else
			is_patch_aft=1
		fi
	else
		do_aft=1
	fi
        read -p "Do you want to upgrade SAP (Y/n): " do_sap
        if [ "$do_sap" == "Y" -o "$do_sap" == "y" ] ; then
                do_sap=0
                read -p "Please provide the current version to initiate upgrade: " cur_versn_sap
                read -p "Please provide the HP Unix module upgrade binary location(Should be uploaded in this host): " upgd_bin_hp_sap
                [ ! -f $upgd_bin_hp_sap ] && ( echo "ERROR: Binary not accessable."; exit 1 )
                upgd_bin_hash_hp_sap=$(cksum $upgd_bin_hp_sap | awk '{ print $1 }')
                read -p "Please provide the Linux(x86_64) module upgrade binary location(Should be uploaded in this host): " upgd_bin_linux_sap
                [ ! -f $upgd_bin_linux_sap ] && ( echo "ERROR: Binary not accessable."; exit 1 )
                upgd_bin_hash_linux_sap=$(cksum $upgd_bin_linux_sap | awk '{ print $1 }')
                read -p "Please provide the AIX module upgrade binary location(Should be uploaded in this host): " upgd_bin_aix_sap
                [ ! -f $upgd_bin_aix_sap ] && ( echo "ERROR: Binary not accessable."; exit 1 )
                upgd_bin_hash_aix_sap=$(cksum $upgd_bin_aix_sap | awk '{ print $1 }')
                read -p "Please provide the silent install option file: " optn_file_sap
                [ ! -f $optn_file_sap ] && ( echo "ERROR: File not accessable."; exit 1 )
		optn_file_hash_sap=$(cksum $optn_file_sap | awk '{ print $1 }')
                read -p "Do you want to patch SAP (Y/n): " is_patch_sap
                if [ "$is_patch_sap" == "Y" -o "$is_patch_sap" == "y" ] ; then
                        is_patch_sap=0
                        read -p "Please provide the HP Unix patch binary location for SAP(Should be uploaded in this host): " patch_bin_hp_sap
                        [ ! -f $patch_bin_hp_sap ] && ( echo "ERROR: Binary not accessable."; exit 1 )
                        patch_bin_hash_hp_sap=$(cksum $patch_bin_hp_sap | awk '{ print $1 }')
                        read -p "Please provide the Linux(x86_64) patch binary location for SAP(Should be uploaded in this host): " patch_bin_linux_sap
                        [ ! -f $patch_bin_linux_sap ] && ( echo "ERROR: Binary not accessable."; exit 1 )
                        patch_bin_hash_linux_sap=$(cksum $patch_bin_linux_sap | awk '{ print $1 }')
                        read -p "Please provide the AIX patch binary location for SAP(Should be uploaded in this host): " patch_bin_aix_sap
                        [ ! -f $patch_bin_aix_sap ] && ( echo "ERROR: Binary not accessable."; exit 1 )
                        patch_bin_hash_aix_sap=$(cksum $patch_bin_aix_sap | awk '{ print $1 }')
                else
                        is_patch_sap=1
                fi
        else
                do_sap=1
        fi
        read -p "Do you want to upgrade INFORMATICA (Y/n): " do_inform
        if [ "$do_inform" == "Y" -o "$do_inform" == "y" ] ; then
                do_inform=0
                read -p "Please provide the current version to initiate upgrade: " cur_versn_inform
                read -p "Please provide the HP Unix module upgrade binary location(Should be uploaded in this host): " upgd_bin_hp_inform
                [ ! -f $upgd_bin_hp_inform ] && ( echo "ERROR: Binary not accessable."; exit 1 )
                upgd_bin_hash_hp_inform=$(cksum $upgd_bin_hp_inform | awk '{ print $1 }')
                read -p "Please provide the Linux(x86_64) module upgrade binary location(Should be uploaded in this host): " upgd_bin_linux_inform
                [ ! -f $upgd_bin_linux_inform ] && ( echo "ERROR: Binary not accessable."; exit 1 )
                upgd_bin_hash_linux_inform=$(cksum $upgd_bin_linux_inform | awk '{ print $1 }')
                read -p "Please provide the AIX module upgrade binary location(Should be uploaded in this host): " upgd_bin_aix_inform
                [ ! -f $upgd_bin_aix_inform ] && ( echo "ERROR: Binary not accessable."; exit 1 )
                upgd_bin_hash_aix_inform=$(cksum $upgd_bin_aix_inform | awk '{ print $1 }')
                read -p "Please provide the silent install option file: " optn_file_inform
                [ ! -f $optn_file_inform ] && ( echo "ERROR: File not accessable."; exit 1 )
		optn_file_hash_inform=$(cksum $optn_file_inform | awk '{ print $1 }')
                read -p "Do you want to patch INFORMATICA (Y/n): " is_patch_inform
                if [ "$is_patch_inform" == "Y" -o "$is_patch_inform" == "y" ] ; then
                        is_patch_inform=0
                        read -p "Please provide the HP Unix patch binary location for INFORMATICA(Should be uploaded in this host): " patch_bin_hp_inform
                        [ ! -f $patch_bin_hp_inform ] && ( echo "ERROR: Binary not accessable."; exit 1 )
                        patch_bin_hash_hp_inform=$(cksum $patch_bin_hp_inform | awk '{ print $1 }')
                        read -p "Please provide the Linux(x86_64) patch binary location for INFORMATICA(Should be uploaded in this host): " patch_bin_linux_inform
                        [ ! -f $patch_bin_linux_inform ] && ( echo "ERROR: Binary not accessable."; exit 1 )
                        patch_bin_hash_linux_inform=$(cksum $patch_bin_linux_inform | awk '{ print $1 }')
                        read -p "Please provide the AIX patch binary location for INFORMATICA(Should be uploaded in this host): " patch_bin_aix_inform
                        [ ! -f $patch_bin_aix_inform ] && ( echo "ERROR: Binary not accessable."; exit 1 )
                        patch_bin_hash_aix_inform=$(cksum $patch_bin_aix_inform | awk '{ print $1 }')
                else
                        is_patch_inform=1
                fi
        else
                do_inform=1
        fi
        read -p "Do you want to upgrade HADOOP (Y/n): " do_hdp
        if [ "$do_hdp" == "Y" -o "$do_hdp" == "y" ] ; then
                do_hdp=0
                read -p "Please provide the current version to initiate upgrade: " cur_versn_hdp
                read -p "Please provide the HP Unix module upgrade binary location(Should be uploaded in this host): " upgd_bin_hp_hdp
                [ ! -f $upgd_bin_hp_hdp ] && ( echo "ERROR: Binary not accessable."; exit 1 )
                upgd_bin_hash_hp_hdp=$(cksum $upgd_bin_hp_hdp | awk '{ print $1 }')
                read -p "Please provide the Linux(x86_64) module upgrade binary location(Should be uploaded in this host): " upgd_bin_linux_hdp
                [ ! -f $upgd_bin_linux_hdp ] && ( echo "ERROR: Binary not accessable."; exit 1 )
                upgd_bin_hash_linux_hdp=$(cksum $upgd_bin_linux_hdp | awk '{ print $1 }')
                read -p "Please provide the AIX module upgrade binary location(Should be uploaded in this host): " upgd_bin_aix_hdp
                [ ! -f $upgd_bin_aix_hdp ] && ( echo "ERROR: Binary not accessable."; exit 1 )
                upgd_bin_hash_aix_hdp=$(cksum $upgd_bin_aix_hdp | awk '{ print $1 }')
                read -p "Please provide the silent install option file: " optn_file_hdp
                [ ! -f $optn_file_hdp ] && ( echo "ERROR: File not accessable."; exit 1 )
		optn_file_hash_hdp=$(cksum $optn_file_hdp | awk '{ print $1 }')
                read -p "Do you want to patch HADOOP (Y/n): " is_patch_hdp
                if [ "$is_patch_hdp" == "Y" -o "$is_patch_hdp" == "y" ] ; then
                        is_patch_hdp=0
                        read -p "Please provide the HP Unix patch binary location for HADOOP(Should be uploaded in this host): " patch_bin_hp_hdp
                        [ ! -f $patch_bin_hp_hdp ] && ( echo "ERROR: Binary not accessable."; exit 1 )
                        patch_bin_hash_hp_hdp=$(cksum $patch_bin_hp_hdp | awk '{ print $1 }')
                        read -p "Please provide the Linux(x86_64) patch binary location for HADOOP(Should be uploaded in this host): " patch_bin_linux_hdp
                        [ ! -f $patch_bin_linux_hdp ] && ( echo "ERROR: Binary not accessable."; exit 1 )
                        patch_bin_hash_linux_hdp=$(cksum $patch_bin_linux_hdp | awk '{ print $1 }')
                        read -p "Please provide the AIX patch binary location for HADOOP(Should be uploaded in this host): " patch_bin_aix_hdp
                        [ ! -f $patch_bin_aix_hdp ] && ( echo "ERROR: Binary not accessable."; exit 1 )
                        patch_bin_hash_aix_hdp=$(cksum $patch_bin_aix_hdp | awk '{ print $1 }')
                else
                        is_patch_hdp=1
                fi
        else
                do_hdp=1
        fi
else
        is_module=1
fi

echo "Thanks for the input, kindly wait for the script to prepare the setup."

if [ -d ${script_home}/${activity_id} -o -f ${script_home}/run_upgrade_${activity_id}.sh ] ; then
	echo "ERROR: There is already a migration scenario created for the same. Thus quiting setup!!!"
	exit 1
fi

mkdir -p ${script_home}/log/${activity_id}
mkdir -p ${script_home}/${activity_id}
mkdir -p ${script_home}/${activity_id}/linux/
mkdir -p ${script_home}/${activity_id}/hpux/
mkdir -p ${script_home}/${activity_id}/aix/
cp lib/run_upgrade.sh run_upgrade_${activity_id}.sh
cp ${optn_file} ${script_home}/${activity_id}/hpux/upgrade.xml
cp ${optn_file} ${script_home}/${activity_id}/linux/upgrade.xml
cp ${optn_file} ${script_home}/${activity_id}/aix/upgrade.xml
cp $upgd_bin_hp ${script_home}/${activity_id}/hpux/
cp $upgd_bin_lnx ${script_home}/${activity_id}/linux/
cp $upgd_bin_aix ${script_home}/${activity_id}/aix/
cp lib/upgrade_hpux.sh ${script_home}/${activity_id}/hpux/upgrade.sh
cp lib/upgrade_linux.sh ${script_home}/${activity_id}/linux/upgrade.sh
cp lib/upgrade_aix.sh ${script_home}/${activity_id}/aix/upgrade.sh

if [ "$is_patch" == "Y" -o "$is_patch" == "y" ] ; then
	cp $patch_bin_hp ${script_home}/${activity_id}/hpux/
        cp $patch_bin_lnx ${script_home}/${activity_id}/linux/
        cp $patch_bin_aix ${script_home}/${activity_id}/aix/
        sed -i 's/@@@IS_PATCH_REQUIRE@@@/0/g' ${script_home}/${activity_id}/hpux/upgrade.sh
        sed -i 's/@@@IS_PATCH_REQUIRE@@@/0/g' ${script_home}/${activity_id}/linux/upgrade.sh
        sed -i 's/@@@IS_PATCH_REQUIRE@@@/0/g' ${script_home}/${activity_id}/aix/upgrade.sh
	sed -i 's/@@@PATCH_BINARY@@@/'$(basename $patch_bin_hp)'/g' ${script_home}/${activity_id}/hpux/upgrade.sh
	sed -i 's/@@@PATCH_BINARY@@@/'$(basename $patch_bin_lnx)'/g' ${script_home}/${activity_id}/linux/upgrade.sh
        sed -i 's/@@@PATCH_BINARY@@@/'$(basename $patch_bin_aix)'/g' ${script_home}/${activity_id}/aix/upgrade.sh
	sed -i 's/@@@PATCH_BINARY_HASH@@@/'${patch_bin_hp_hash}'/g' ${script_home}/${activity_id}/hpux/upgrade.sh
	sed -i 's/@@@PATCH_BINARY_HASH@@@/'${patch_bin_lnx_hash}'/g' ${script_home}/${activity_id}/linux/upgrade.sh
        sed -i 's/@@@PATCH_BINARY_HASH@@@/'${patch_bin_aix_hash}'/g' ${script_home}/${activity_id}/aix/upgrade.sh
	sed -i 's/@@@PATCH_VERSION@@@/'${patch_id}'/g' ${script_home}/${activity_id}/hpux/upgrade.sh
	sed -i 's/@@@PATCH_VERSION@@@/'${patch_id}'/g' ${script_home}/${activity_id}/linux/upgrade.sh
	sed -i 's/@@@PATCH_VERSION@@@/'${patch_id}'/g' ${script_home}/${activity_id}/aix/upgrade.sh
else
	sed -i 's/@@@IS_PATCH_REQUIRE@@@/1/g' ${script_home}/${activity_id}/hpux/upgrade.sh
        sed -i 's/@@@IS_PATCH_REQUIRE@@@/1/g' ${script_home}/${activity_id}/linux/upgrade.sh
        sed -i 's/@@@IS_PATCH_REQUIRE@@@/1/g' ${script_home}/${activity_id}/aix/upgrade.sh
fi

if [ $is_proto_value -eq 0 ] ; then
        sed -i 's/@@@IS_PROTOCOL_UPGRADE_REQUIRE@@@/0/g' ${script_home}/${activity_id}/hpux/upgrade.sh
        sed -i 's/@@@IS_PROTOCOL_UPGRADE_REQUIRE@@@/0/g' ${script_home}/${activity_id}/linux/upgrade.sh
        sed -i 's/@@@IS_PROTOCOL_UPGRADE_REQUIRE@@@/0/g' ${script_home}/${activity_id}/aix/upgrade.sh
        sed -i 's/@@@FINAL_PROTOCOL_VERSION@@@/'${final_proto_ver}'/g' ${script_home}/${activity_id}/hpux/upgrade.sh
        sed -i 's/@@@FINAL_PROTOCOL_VERSION@@@/'${final_proto_ver}'/g'  ${script_home}/${activity_id}/linux/upgrade.sh
        sed -i 's/@@@FINAL_PROTOCOL_VERSION@@@/'${final_proto_ver}'/g'  ${script_home}/${activity_id}/aix/upgrade.sh
else
        sed -i 's/@@@IS_PROTOCOL_UPGRADE_REQUIRE@@@/1/g' ${script_home}/${activity_id}/hpux/upgrade.sh
        sed -i 's/@@@IS_PROTOCOL_UPGRADE_REQUIRE@@@/1/g' ${script_home}/${activity_id}/linux/upgrade.sh
        sed -i 's/@@@IS_PROTOCOL_UPGRADE_REQUIRE@@@/1/g' ${script_home}/${activity_id}/aix/upgrade.sh
fi

if [ $is_module -eq 0 ] ; then
        sed -i 's/@@@IS_MODULE_UPGRADE_REQUIRE@@@/0/g' ${script_home}/${activity_id}/hpux/upgrade.sh
        sed -i 's/@@@IS_MODULE_UPGRADE_REQUIRE@@@/0/g' ${script_home}/${activity_id}/linux/upgrade.sh
        sed -i 's/@@@IS_MODULE_UPGRADE_REQUIRE@@@/0/g' ${script_home}/${activity_id}/aix/upgrade.sh
	if [ $do_aft -eq 0 ] ; then
	        sed -i 's/@@@IS_AFT_UPGRADE_REQUIRE@@@/0/g' ${script_home}/${activity_id}/hpux/upgrade.sh
        	sed -i 's/@@@IS_AFT_UPGRADE_REQUIRE@@@/0/g' ${script_home}/${activity_id}/linux/upgrade.sh
	        sed -i 's/@@@IS_AFT_UPGRADE_REQUIRE@@@/0/g' ${script_home}/${activity_id}/aix/upgrade.sh
        	sed -i 's/@@@AFT_CURRENT_VERSION@@@/'${cur_versn_aft}'/g' ${script_home}/${activity_id}/hpux/upgrade.sh
	        sed -i 's/@@@AFT_CURRENT_VERSION@@@/'${cur_versn_aft}'/g' ${script_home}/${activity_id}/linux/upgrade.sh
        	sed -i 's/@@@AFT_CURRENT_VERSION@@@/'${cur_versn_aft}'/g' ${script_home}/${activity_id}/aix/upgrade.sh
		sed -i 's/@@@AFT_UPGRADE_BINARY@@@/'$(basename $upgd_bin_hp_aft)'/g' ${script_home}/${activity_id}/hpux/upgrade.sh
                sed -i 's/@@@AFT_UPGRADE_BINARY@@@/'$(basename $upgd_bin_linux_aft)'/g' ${script_home}/${activity_id}/linux/upgrade.sh
                sed -i 's/@@@AFT_UPGRADE_BINARY@@@/'$(basename $upgd_bin_aix_aft)'/g' ${script_home}/${activity_id}/aix/upgrade.sh
                sed -i 's/@@@AFT_UPGRADE_BINARY_HASH@@@/'${upgd_bin_hash_hp_aft}'/g' ${script_home}/${activity_id}/hpux/upgrade.sh
                sed -i 's/@@@AFT_UPGRADE_BINARY_HASH@@@/'${upgd_bin_hash_linux_aft}'/g' ${script_home}/${activity_id}/linux/upgrade.sh
                sed -i 's/@@@AFT_UPGRADE_BINARY_HASH@@@/'${upgd_bin_hash_aix_aft}'/g' ${script_home}/${activity_id}/aix/upgrade.sh
                sed -i 's/@@@AFT_UPGRADE_CONTRL_FILE@@@/'$(basename $optn_file_aft)'/g' ${script_home}/${activity_id}/hpux/upgrade.sh
                sed -i 's/@@@AFT_UPGRADE_CONTRL_FILE@@@/'$(basename $optn_file_aft)'/g' ${script_home}/${activity_id}/linux/upgrade.sh
                sed -i 's/@@@AFT_UPGRADE_CONTRL_FILE@@@/'$(basename $optn_file_aft)'/g' ${script_home}/${activity_id}/aix/upgrade.sh
                sed -i 's/@@@AFT_UPGRADE_CONTRL_HASH@@@/'${optn_file_hash_aft}'/g' ${script_home}/${activity_id}/hpux/upgrade.sh
                sed -i 's/@@@AFT_UPGRADE_CONTRL_HASH@@@/'${optn_file_hash_aft}'/g' ${script_home}/${activity_id}/linux/upgrade.sh
                sed -i 's/@@@AFT_UPGRADE_CONTRL_HASH@@@/'${optn_file_hash_aft}'/g' ${script_home}/${activity_id}/aix/upgrade.sh
		cp $upgd_bin_hp_aft ${script_home}/${activity_id}/hpux/
		cp $upgd_bin_linux_aft ${script_home}/${activity_id}/linux/
		cp $upgd_bin_aix_aft ${script_home}/${activity_id}/aix/
		cp $optn_file_aft ${script_home}/${activity_id}/hpux/
                cp $optn_file_aft ${script_home}/${activity_id}/linux/
                cp $optn_file_aft ${script_home}/${activity_id}/aix/
                if [ $is_patch_aft -eq 0 ] ; then
                        sed -i 's/@@@AFT_PATCH_IS@@@/0/g' ${script_home}/${activity_id}/hpux/upgrade.sh
                        sed -i 's/@@@AFT_PATCH_IS@@@/0/g' ${script_home}/${activity_id}/linux/upgrade.sh
                        sed -i 's/@@@AFT_PATCH_IS@@@/0/g' ${script_home}/${activity_id}/aix/upgrade.sh
                	sed -i 's/@@@AFT_PATCH_BINARY@@@/'$(basename $patch_bin_hp_aft)'/g' ${script_home}/${activity_id}/hpux/upgrade.sh
                        sed -i 's/@@@AFT_PATCH_BINARY@@@/'$(basename $patch_bin_linux_aft)'/g' ${script_home}/${activity_id}/linux/upgrade.sh
                        sed -i 's/@@@AFT_PATCH_BINARY@@@/'$(basename $patch_bin_aix_aft)'/g' ${script_home}/${activity_id}/aix/upgrade.sh
                        sed -i 's/@@@AFT_PATCH_BINARY_HASH@@@/'${patch_bin_hash_hp_aft}'/g' ${script_home}/${activity_id}/hpux/upgrade.sh
                        sed -i 's/@@@AFT_PATCH_BINARY_HASH@@@/'${patch_bin_hash_linux_aft}'/g' ${script_home}/${activity_id}/linux/upgrade.sh
                        sed -i 's/@@@AFT_PATCH_BINARY_HASH@@@/'${patch_bin_hash_aix_aft}'/g' ${script_home}/${activity_id}/aix/upgrade.sh
                        cp $patch_bin_hp_aft ${script_home}/${activity_id}/hpux/
                        cp $patch_bin_linux_aft ${script_home}/${activity_id}/linux/
                        cp $patch_bin_aix_aft ${script_home}/${activity_id}/aix/
		else
                        sed -i 's/@@@AFT_PATCH_IS@@@/1/g' ${script_home}/${activity_id}/hpux/upgrade.sh
                        sed -i 's/@@@AFT_PATCH_IS@@@/1/g' ${script_home}/${activity_id}/linux/upgrade.sh
                        sed -i 's/@@@AFT_PATCH_IS@@@/1/g' ${script_home}/${activity_id}/aix/upgrade.sh
		fi
	else
                sed -i 's/@@@IS_AFT_UPGRADE_REQUIRE@@@/1/g' ${script_home}/${activity_id}/hpux/upgrade.sh
                sed -i 's/@@@IS_AFT_UPGRADE_REQUIRE@@@/1/g' ${script_home}/${activity_id}/linux/upgrade.sh
                sed -i 's/@@@IS_AFT_UPGRADE_REQUIRE@@@/1/g' ${script_home}/${activity_id}/aix/upgrade.sh
	fi
        if [ $do_sap -eq 0 ] ; then
                sed -i 's/@@@IS_SAP_UPGRADE_REQUIRE@@@/0/g' ${script_home}/${activity_id}/hpux/upgrade.sh
                sed -i 's/@@@IS_SAP_UPGRADE_REQUIRE@@@/0/g' ${script_home}/${activity_id}/linux/upgrade.sh
                sed -i 's/@@@IS_SAP_UPGRADE_REQUIRE@@@/0/g' ${script_home}/${activity_id}/aix/upgrade.sh
                sed -i 's/@@@SAP_CURRENT_VERSION@@@/'${cur_versn_sap}'/g' ${script_home}/${activity_id}/hpux/upgrade.sh
                sed -i 's/@@@SAP_CURRENT_VERSION@@@/'${cur_versn_sap}'/g' ${script_home}/${activity_id}/linux/upgrade.sh
                sed -i 's/@@@SAP_CURRENT_VERSION@@@/'${cur_versn_sap}'/g' ${script_home}/${activity_id}/aix/upgrade.sh
                sed -i 's/@@@SAP_UPGRADE_BINARY@@@/'$(basename $upgd_bin_hp_sap)'/g' ${script_home}/${activity_id}/hpux/upgrade.sh
                sed -i 's/@@@SAP_UPGRADE_BINARY@@@/'$(basename $upgd_bin_linux_sap)'/g' ${script_home}/${activity_id}/linux/upgrade.sh
                sed -i 's/@@@SAP_UPGRADE_BINARY@@@/'$(basename $upgd_bin_aix_sap)'/g' ${script_home}/${activity_id}/aix/upgrade.sh
                sed -i 's/@@@SAP_UPGRADE_BINARY_HASH@@@/'${upgd_bin_hash_hp_sap}'/g' ${script_home}/${activity_id}/hpux/upgrade.sh
                sed -i 's/@@@SAP_UPGRADE_BINARY_HASH@@@/'${upgd_bin_hash_linux_sap}'/g' ${script_home}/${activity_id}/linux/upgrade.sh
                sed -i 's/@@@SAP_UPGRADE_BINARY_HASH@@@/'${upgd_bin_hash_aix_sap}'/g' ${script_home}/${activity_id}/aix/upgrade.sh
                sed -i 's/@@@SAP_UPGRADE_CONTRL_FILE@@@/'$(basename $optn_file_sap)'/g' ${script_home}/${activity_id}/hpux/upgrade.sh
                sed -i 's/@@@SAP_UPGRADE_CONTRL_FILE@@@/'$(basename $optn_file_sap)'/g' ${script_home}/${activity_id}/linux/upgrade.sh
                sed -i 's/@@@SAP_UPGRADE_CONTRL_FILE@@@/'$(basename $optn_file_sap)'/g' ${script_home}/${activity_id}/aix/upgrade.sh
                sed -i 's/@@@SAP_UPGRADE_CONTRL_HASH@@@/'${optn_file_hash_sap}'/g' ${script_home}/${activity_id}/hpux/upgrade.sh
                sed -i 's/@@@SAP_UPGRADE_CONTRL_HASH@@@/'${optn_file_hash_sap}'/g' ${script_home}/${activity_id}/linux/upgrade.sh
                sed -i 's/@@@SAP_UPGRADE_CONTRL_HASH@@@/'${optn_file_hash_sap}'/g' ${script_home}/${activity_id}/aix/upgrade.sh
                cp $upgd_bin_hp_sap ${script_home}/${activity_id}/hpux/
                cp $upgd_bin_linux_sap ${script_home}/${activity_id}/linux/
                cp $upgd_bin_aix_sap ${script_home}/${activity_id}/aix/
                cp $optn_file_sap ${script_home}/${activity_id}/hpux/
                cp $optn_file_sap ${script_home}/${activity_id}/linux/
                cp $optn_file_sap ${script_home}/${activity_id}/aix/
                if [ $is_patch_sap -eq 0 ] ; then
                        sed -i 's/@@@SAP_PATCH_IS@@@/0/g' ${script_home}/${activity_id}/hpux/upgrade.sh
                        sed -i 's/@@@SAP_PATCH_IS@@@/0/g' ${script_home}/${activity_id}/linux/upgrade.sh
                        sed -i 's/@@@SAP_PATCH_IS@@@/0/g' ${script_home}/${activity_id}/aix/upgrade.sh
                        sed -i 's/@@@SAP_PATCH_BINARY@@@/'$(basename $patch_bin_hp_sap)'/g' ${script_home}/${activity_id}/hpux/upgrade.sh
                        sed -i 's/@@@SAP_PATCH_BINARY@@@/'$(basename $patch_bin_linux_sap)'/g' ${script_home}/${activity_id}/linux/upgrade.sh
                        sed -i 's/@@@SAP_PATCH_BINARY@@@/'$(basename $patch_bin_aix_sap)'/g' ${script_home}/${activity_id}/aix/upgrade.sh
                        sed -i 's/@@@SAP_PATCH_BINARY_HASH@@@/'${patch_bin_hash_hp_sap}'/g' ${script_home}/${activity_id}/hpux/upgrade.sh
                        sed -i 's/@@@SAP_PATCH_BINARY_HASH@@@/'${patch_bin_hash_linux_sap}'/g' ${script_home}/${activity_id}/linux/upgrade.sh
                        sed -i 's/@@@SAP_PATCH_BINARY_HASH@@@/'${patch_bin_hash_aix_sap}'/g' ${script_home}/${activity_id}/aix/upgrade.sh
			cp $patch_bin_hp_sap ${script_home}/${activity_id}/hpux/
                        cp $patch_bin_linux_sap ${script_home}/${activity_id}/linux/
                        cp $patch_bin_aix_sap ${script_home}/${activity_id}/aix/
                else
                        sed -i 's/@@@SAP_PATCH_IS@@@/1/g' ${script_home}/${activity_id}/hpux/upgrade.sh
                        sed -i 's/@@@SAP_PATCH_IS@@@/1/g' ${script_home}/${activity_id}/linux/upgrade.sh
                        sed -i 's/@@@SAP_PATCH_IS@@@/1/g' ${script_home}/${activity_id}/aix/upgrade.sh
                fi
		else
                sed -i 's/@@@IS_SAP_UPGRADE_REQUIRE@@@/1/g' ${script_home}/${activity_id}/hpux/upgrade.sh
                sed -i 's/@@@IS_SAP_UPGRADE_REQUIRE@@@/1/g' ${script_home}/${activity_id}/linux/upgrade.sh
                sed -i 's/@@@IS_SAP_UPGRADE_REQUIRE@@@/1/g' ${script_home}/${activity_id}/aix/upgrade.sh
        fi
        if [ $do_inform -eq 0 ] ; then
                sed -i 's/@@@IS_INFORMATICA_UPGRADE_REQUIRE@@@/0/g' ${script_home}/${activity_id}/hpux/upgrade.sh
                sed -i 's/@@@IS_INFORMATICA_UPGRADE_REQUIRE@@@/0/g' ${script_home}/${activity_id}/linux/upgrade.sh
                sed -i 's/@@@IS_INFORMATICA_UPGRADE_REQUIRE@@@/0/g' ${script_home}/${activity_id}/aix/upgrade.sh
                sed -i 's/@@@INFORMATICA_CURRENT_VERSION@@@/'${cur_versn_inform}'/g' ${script_home}/${activity_id}/hpux/upgrade.sh
                sed -i 's/@@@INFORMATICA_CURRENT_VERSION@@@/'${cur_versn_inform}'/g' ${script_home}/${activity_id}/linux/upgrade.sh
                sed -i 's/@@@INFORMATICA_CURRENT_VERSION@@@/'${cur_versn_inform}'/g' ${script_home}/${activity_id}/aix/upgrade.sh
                sed -i 's/@@@INFORMATICA_UPGRADE_BINARY@@@/'$(basename $upgd_bin_hp_inform)'/g' ${script_home}/${activity_id}/hpux/upgrade.sh
                sed -i 's/@@@INFORMATICA_UPGRADE_BINARY@@@/'$(basename $upgd_bin_linux_inform)'/g' ${script_home}/${activity_id}/linux/upgrade.sh
                sed -i 's/@@@INFORMATICA_UPGRADE_BINARY@@@/'$(basename $upgd_bin_aix_inform)'/g' ${script_home}/${activity_id}/aix/upgrade.sh
                sed -i 's/@@@INFORMATICA_UPGRADE_BINARY_HASH@@@/'${upgd_bin_hash_hp_inform}'/g' ${script_home}/${activity_id}/hpux/upgrade.sh
                sed -i 's/@@@INFORMATICA_UPGRADE_BINARY_HASH@@@/'${upgd_bin_hash_linux_inform}'/g' ${script_home}/${activity_id}/linux/upgrade.sh
                sed -i 's/@@@INFORMATICA_UPGRADE_BINARY_HASH@@@/'${upgd_bin_hash_aix_inform}'/g' ${script_home}/${activity_id}/aix/upgrade.sh
                sed -i 's/@@@INFORMATICA_UPGRADE_CONTRL_FILE@@@/'$(basename $optn_file_inform)'/g' ${script_home}/${activity_id}/hpux/upgrade.sh
                sed -i 's/@@@INFORMATICA_UPGRADE_CONTRL_FILE@@@/'$(basename $optn_file_inform)'/g' ${script_home}/${activity_id}/linux/upgrade.sh
                sed -i 's/@@@INFORMATICA_UPGRADE_CONTRL_FILE@@@/'$(basename $optn_file_inform)'/g' ${script_home}/${activity_id}/aix/upgrade.sh
                sed -i 's/@@@INFORMATICA_UPGRADE_CONTRL_HASH@@@/'${optn_file_hash_inform}'/g' ${script_home}/${activity_id}/hpux/upgrade.sh
                sed -i 's/@@@INFORMATICA_UPGRADE_CONTRL_HASH@@@/'${optn_file_hash_inform}'/g' ${script_home}/${activity_id}/linux/upgrade.sh
                sed -i 's/@@@INFORMATICA_UPGRADE_CONTRL_HASH@@@/'${optn_file_hash_inform}'/g' ${script_home}/${activity_id}/aix/upgrade.sh
                cp $upgd_bin_hp_inform ${script_home}/${activity_id}/hpux/
                cp $upgd_bin_linux_inform ${script_home}/${activity_id}/linux/
                cp $upgd_bin_aix_inform ${script_home}/${activity_id}/aix/
                cp $optn_file_inform ${script_home}/${activity_id}/hpux/
                cp $optn_file_inform ${script_home}/${activity_id}/linux/
                cp $optn_file_inform ${script_home}/${activity_id}/aix/
                if [ $is_patch_inform -eq 0 ] ; then
                        sed -i 's/@@@INFORMATICA_PATCH_IS@@@/0/g' ${script_home}/${activity_id}/hpux/upgrade.sh
                        sed -i 's/@@@INFORMATICA_PATCH_IS@@@/0/g' ${script_home}/${activity_id}/linux/upgrade.sh
                        sed -i 's/@@@INFORMATICA_PATCH_IS@@@/0/g' ${script_home}/${activity_id}/aix/upgrade.sh
                        sed -i 's/@@@INFORMATICA_PATCH_BINARY@@@/'$(basename $patch_bin_hp_inform)'/g' ${script_home}/${activity_id}/hpux/upgrade.sh
                        sed -i 's/@@@INFORMATICA_PATCH_BINARY@@@/'$(basename $patch_bin_linux_inform)'/g' ${script_home}/${activity_id}/linux/upgrade.sh
                        sed -i 's/@@@INFORMATICA_PATCH_BINARY@@@/'$(basename $patch_bin_aix_inform)'/g' ${script_home}/${activity_id}/aix/upgrade.sh
                        sed -i 's/@@@INFORMATICA_PATCH_BINARY_HASH@@@/'${patch_bin_hash_hp_inform}'/g' ${script_home}/${activity_id}/hpux/upgrade.sh
                        sed -i 's/@@@INFORMATICA_PATCH_BINARY_HASH@@@/'${patch_bin_hash_linux_inform}'/g' ${script_home}/${activity_id}/linux/upgrade.sh
                        sed -i 's/@@@INFORMATICA_PATCH_BINARY_HASH@@@/'${patch_bin_hash_aix_inform}'/g' ${script_home}/${activity_id}/aix/upgrade.sh
		        cp $patch_bin_hp_inform ${script_home}/${activity_id}/hpux/
                        cp $patch_bin_linux_inform ${script_home}/${activity_id}/linux/
                        cp $patch_bin_aix_inform ${script_home}/${activity_id}/aix/
                else
                        sed -i 's/@@@INFORMATICA_PATCH_IS@@@/1/g' ${script_home}/${activity_id}/hpux/upgrade.sh
                        sed -i 's/@@@INFORMATICA_PATCH_IS@@@/1/g' ${script_home}/${activity_id}/linux/upgrade.sh
                        sed -i 's/@@@INFORMATICA_PATCH_IS@@@/1/g' ${script_home}/${activity_id}/aix/upgrade.sh
                fi
		else
                sed -i 's/@@@IS_INFORMATICA_UPGRADE_REQUIRE@@@/1/g' ${script_home}/${activity_id}/hpux/upgrade.sh
                sed -i 's/@@@IS_INFORMATICA_UPGRADE_REQUIRE@@@/1/g' ${script_home}/${activity_id}/linux/upgrade.sh
                sed -i 's/@@@IS_INFORMATICA_UPGRADE_REQUIRE@@@/1/g' ${script_home}/${activity_id}/aix/upgrade.sh
        fi
        if [ $do_hdp -eq 0 ] ; then
                sed -i 's/@@@IS_HADOOP_UPGRADE_REQUIRE@@@/0/g' ${script_home}/${activity_id}/hpux/upgrade.sh
                sed -i 's/@@@IS_HADOOP_UPGRADE_REQUIRE@@@/0/g' ${script_home}/${activity_id}/linux/upgrade.sh
                sed -i 's/@@@IS_HADOOP_UPGRADE_REQUIRE@@@/0/g' ${script_home}/${activity_id}/aix/upgrade.sh
                sed -i 's/@@@HADOOP_CURRENT_VERSION@@@/'${cur_versn_hdp}'/g' ${script_home}/${activity_id}/hpux/upgrade.sh
                sed -i 's/@@@HADOOP_CURRENT_VERSION@@@/'${cur_versn_hdp}'/g' ${script_home}/${activity_id}/linux/upgrade.sh
                sed -i 's/@@@HADOOP_CURRENT_VERSION@@@/'${cur_versn_hdp}'/g' ${script_home}/${activity_id}/aix/upgrade.sh
                sed -i 's/@@@HADOOP_UPGRADE_BINARY@@@/'$(basename $upgd_bin_hp_hdp)'/g' ${script_home}/${activity_id}/hpux/upgrade.sh
                sed -i 's/@@@HADOOP_UPGRADE_BINARY@@@/'$(basename $upgd_bin_linux_hdp)'/g' ${script_home}/${activity_id}/linux/upgrade.sh
                sed -i 's/@@@HADOOP_UPGRADE_BINARY@@@/'$(basename $upgd_bin_aix_hdp)'/g' ${script_home}/${activity_id}/aix/upgrade.sh
                sed -i 's/@@@HADOOP_UPGRADE_BINARY_HASH@@@/'${upgd_bin_hash_hp_hdp}'/g' ${script_home}/${activity_id}/hpux/upgrade.sh
                sed -i 's/@@@HADOOP_UPGRADE_BINARY_HASH@@@/'${upgd_bin_hash_linux_hdp}'/g' ${script_home}/${activity_id}/linux/upgrade.sh
                sed -i 's/@@@HADOOP_UPGRADE_BINARY_HASH@@@/'${upgd_bin_hash_aix_hdp}'/g' ${script_home}/${activity_id}/aix/upgrade.sh
                sed -i 's/@@@HADOOP_UPGRADE_CONTRL_FILE@@@/'$(basename $optn_file_hdp)'/g' ${script_home}/${activity_id}/hpux/upgrade.sh
                sed -i 's/@@@HADOOP_UPGRADE_CONTRL_FILE@@@/'$(basename $optn_file_hdp)'/g' ${script_home}/${activity_id}/linux/upgrade.sh
                sed -i 's/@@@HADOOP_UPGRADE_CONTRL_FILE@@@/'$(basename $optn_file_hdp)'/g' ${script_home}/${activity_id}/aix/upgrade.sh
                sed -i 's/@@@HADOOP_UPGRADE_CONTRL_HASH@@@/'${optn_file_hash_hdp}'/g' ${script_home}/${activity_id}/hpux/upgrade.sh
                sed -i 's/@@@HADOOP_UPGRADE_CONTRL_HASH@@@/'${optn_file_hash_hdp}'/g' ${script_home}/${activity_id}/linux/upgrade.sh
                sed -i 's/@@@HADOOP_UPGRADE_CONTRL_HASH@@@/'${optn_file_hash_hdp}'/g' ${script_home}/${activity_id}/aix/upgrade.sh
                cp $upgd_bin_hp_hdp ${script_home}/${activity_id}/hpux/
                cp $upgd_bin_linux_hdp ${script_home}/${activity_id}/linux/
                cp $upgd_bin_aix_hdp ${script_home}/${activity_id}/aix/
                cp $optn_file_hdp ${script_home}/${activity_id}/hpux/
                cp $optn_file_hdp ${script_home}/${activity_id}/linux/
                cp $optn_file_hdp ${script_home}/${activity_id}/aix/
                if [ $is_patch_hdp -eq 0 ] ; then
                        sed -i 's/@@@HADOOP_PATCH_IS@@@/0/g' ${script_home}/${activity_id}/hpux/upgrade.sh
                        sed -i 's/@@@HADOOP_PATCH_IS@@@/0/g' ${script_home}/${activity_id}/linux/upgrade.sh
                        sed -i 's/@@@HADOOP_PATCH_IS@@@/0/g' ${script_home}/${activity_id}/aix/upgrade.sh
                        sed -i 's/@@@HADOOP_PATCH_BINARY@@@/'$(basename $patch_bin_hp_hdp)'/g' ${script_home}/${activity_id}/hpux/upgrade.sh
                        sed -i 's/@@@HADOOP_PATCH_BINARY@@@/'$(basename $patch_bin_linux_hdp)'/g' ${script_home}/${activity_id}/linux/upgrade.sh
                        sed -i 's/@@@HADOOP_PATCH_BINARY@@@/'$(basename $patch_bin_aix_hdp)'/g' ${script_home}/${activity_id}/aix/upgrade.sh
                        sed -i 's/@@@HADOOP_PATCH_BINARY_HASH@@@/'${patch_bin_hash_hp_hdp}'/g' ${script_home}/${activity_id}/hpux/upgrade.sh
                        sed -i 's/@@@HADOOP_PATCH_BINARY_HASH@@@/'${patch_bin_hash_linux_hdp}'/g' ${script_home}/${activity_id}/linux/upgrade.sh
                        sed -i 's/@@@HADOOP_PATCH_BINARY_HASH@@@/'${patch_bin_hash_aix_hdp}'/g' ${script_home}/${activity_id}/aix/upgrade.sh
		        cp $patch_bin_hp_hdp ${script_home}/${activity_id}/hpux/
                        cp $patch_bin_linux_hdp ${script_home}/${activity_id}/linux/
                        cp $patch_bin_aix_hdp ${script_home}/${activity_id}/aix/
                else
                        sed -i 's/@@@HADOOP_PATCH_IS@@@/1/g' ${script_home}/${activity_id}/hpux/upgrade.sh
                        sed -i 's/@@@HADOOP_PATCH_IS@@@/1/g' ${script_home}/${activity_id}/linux/upgrade.sh
                        sed -i 's/@@@HADOOP_PATCH_IS@@@/1/g' ${script_home}/${activity_id}/aix/upgrade.sh
                fi
		else
                sed -i 's/@@@IS_HADOOP_UPGRADE_REQUIRE@@@/1/g' ${script_home}/${activity_id}/hpux/upgrade.sh
                sed -i 's/@@@IS_HADOOP_UPGRADE_REQUIRE@@@/1/g' ${script_home}/${activity_id}/linux/upgrade.sh
                sed -i 's/@@@IS_HADOOP_UPGRADE_REQUIRE@@@/1/g' ${script_home}/${activity_id}/aix/upgrade.sh
        fi
else
        sed -i 's/@@@IS_MODULE_UPGRADE_REQUIRE@@@/1/g' ${script_home}/${activity_id}/hpux/upgrade.sh
        sed -i 's/@@@IS_MODULE_UPGRADE_REQUIRE@@@/1/g' ${script_home}/${activity_id}/linux/upgrade.sh
        sed -i 's/@@@IS_MODULE_UPGRADE_REQUIRE@@@/1/g' ${script_home}/${activity_id}/aix/upgrade.sh
fi

sed -i 's/_@@@CTM_USER_NM@@@_/'${ctm_user}'/g' run_upgrade_${activity_id}.sh
sed -i 's/@@@CTM_USER_PASSWD@@@/'${ctm_usr_passwd}'/g' run_upgrade_${activity_id}.sh
sed -i 's/@@@BINARY_HOME@@@/'${activity_id}'/g' run_upgrade_${activity_id}.sh
sed -i 's/@@@BINARY_HOME@@@/'${activity_id}'/g' ${script_home}/${activity_id}/hpux/upgrade.sh
sed -i 's/@@@BINARY_HOME@@@/'${activity_id}'/g' ${script_home}/${activity_id}/linux/upgrade.sh
sed -i 's/@@@BINARY_HOME@@@/'${activity_id}'/g' ${script_home}/${activity_id}/aix/upgrade.sh
sed -i 's/@@@CURRENT_VERSION@@@/'${cur_vern}'/g' run_upgrade_${activity_id}.sh
sed -i 's/@@@EMAIL_ID@@@/'${email_id}'/g' run_upgrade_${activity_id}.sh
sed -i 's/@@@MINIMUM_FS_SPACE@@@/'${fs_req}'/g' ${script_home}/${activity_id}/hpux/upgrade.sh
sed -i 's/@@@MINIMUM_FS_SPACE@@@/'${fs_req}'/g' ${script_home}/${activity_id}/linux/upgrade.sh
sed -i 's/@@@MINIMUM_FS_SPACE@@@/'${fs_req}'/g' ${script_home}/${activity_id}/aix/upgrade.sh
sed -i 's/@@@UPGRADE_VERSION@@@/'${upgrad_id}'/g' ${script_home}/${activity_id}/hpux/upgrade.sh
sed -i 's/@@@UPGRADE_VERSION@@@/'${upgrad_id}'/g' ${script_home}/${activity_id}/linux/upgrade.sh
sed -i 's/@@@UPGRADE_VERSION@@@/'${upgrad_id}'/g' ${script_home}/${activity_id}/aix/upgrade.sh
sed -i 's/@@@BINARY_HOST@@@/'$(hostname)'/g' ${script_home}/${activity_id}/hpux/upgrade.sh
sed -i 's/@@@BINARY_HOST@@@/'$(hostname)'/g' ${script_home}/${activity_id}/linux/upgrade.sh
sed -i 's/@@@BINARY_HOST@@@/'$(hostname)'/g' ${script_home}/${activity_id}/aix/upgrade.sh
sed -i 's/@@@UPGRADE_BINARY@@@/'$(basename $upgd_bin_hp)'/g' ${script_home}/${activity_id}/hpux/upgrade.sh
sed -i 's/@@@UPGRADE_BINARY@@@/'$(basename $upgd_bin_lnx)'/g' ${script_home}/${activity_id}/linux/upgrade.sh
sed -i 's/@@@UPGRADE_BINARY@@@/'$(basename $upgd_bin_aix)'/g' ${script_home}/${activity_id}/aix/upgrade.sh
sed -i 's/@@@UPGRADE_BINARY_HASH@@@/'${upgd_bin_hp_hash}'/g' ${script_home}/${activity_id}/hpux/upgrade.sh
sed -i 's/@@@UPGRADE_BINARY_HASH@@@/'${upgd_bin_lnx_hash}'/g' ${script_home}/${activity_id}/linux/upgrade.sh
sed -i 's/@@@UPGRADE_BINARY_HASH@@@/'${upgd_bin_aix_hash}'/g' ${script_home}/${activity_id}/aix/upgrade.sh
sed -i 's/@@@OPTION_FILE_HASH@@@/'${optn_file_hash}'/g' ${script_home}/${activity_id}/hpux/upgrade.sh
sed -i 's/@@@OPTION_FILE_HASH@@@/'${optn_file_hash}'/g' ${script_home}/${activity_id}/linux/upgrade.sh
sed -i 's/@@@OPTION_FILE_HASH@@@/'${optn_file_hash}'/g' ${script_home}/${activity_id}/aix/upgrade.sh
chown -R apache:apache ${script_home}/${activity_id}/
chown apache:apache run_upgrade_${activity_id}.sh
chown -R apache:apache ${script_home}/log
chown -R apache:apache ${script_home}/log/${activity_id}
chmod a+rx run_upgrade_${activity_id}.sh
chmod a+rx ${script_home}/log
chmod a+rx ${script_home}/log/${activity_id}

echo ""
echo "Good news, we have successfully created the setup for upgrading ControlM Agent from Version $cur_vern. Below are detail."
echo "Create Host DB file and execute binary run_upgrade_${activity_id}.sh to upgrade ControlM Agent."
