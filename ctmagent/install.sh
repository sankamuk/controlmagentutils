#!/bin/bash
#==================================================================================================================================
# Usage  : Script to install patch and maintain ControlM Upgrade Tool
# Version: 1.0
# Date   : 21-03-2018
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
read -p "Please provide the Linux Upgrade binary location(Should be uploaded in this host): " upgd_bin_lnx
[ ! -f $upgd_bin_lnx ] && ( echo "ERROR: Binary not accessable."; exit 1 )
read -p "Please provide the AIX Upgrade binary location(Should be uploaded in this host): " upgd_bin_aix
[ ! -f $upgd_bin_aix ] && ( echo "ERROR: Binary not accessable."; exit 1 )
read -p "Please provide the silent install option file: " optn_file
[ ! -f $optn_file ] && ( echo "ERROR: Option file not accessable."; exit 1 )
upgd_bin_hp_hash=$(cksum $upgd_bin_hp | awk '{ print $1 }')
upgd_bin_lnx_hash=$(cksum $upgd_bin_lnx | awk '{ print $1 }')
upgd_bin_aix_hash=$(cksum $upgd_bin_aix | awk '{ print $1 }')
optn_file_hash=$(cksum $optn_file | awk '{ print $1 }')
read -p "Do you want to patch after upgrade(Y/n): " is_patch
if [ "$is_patch" == "Y" -o "$is_patch" == "y" ] ; then
	read -p "Please provide the HP Unix patch binary location(Should be uploaded in this host): " patch_bin_hp
	[ ! -f $patch_bin_hp ] && ( echo "ERROR: Binary not accessable."; exit 1 )
	patch_bin_hp_hash=$(cksum $patch_bin_hp | awk '{ print $1 }')
        read -p "Please provide the Linux patch binary location(Should be uploaded in this host): " patch_bin_lnx
        [ ! -f $patch_bin_lnx ] && ( echo "ERROR: Binary not accessable."; exit 1 )
        patch_bin_lnx_hash=$(cksum $patch_bin_lnx | awk '{ print $1 }')
        read -p "Please provide the AIX patch binary location(Should be uploaded in this host): " patch_bin_aix
        [ ! -f $patch_bin_aix ] && ( echo "ERROR: Binary not accessable."; exit 1 )
        patch_bin_aix_hash=$(cksum $patch_bin_aix | awk '{ print $1 }')
	read -p "Please provide the patch version id(This string will be searched in version to validate patching): " patch_id
	activity_id="V${upgrad_id}_P${patch_id}"
else
	activity_id="V${upgrad_id}"
fi
echo "Thanks for the input, kindly wait for the script to prepare the setup."
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
if [ "$is_patch" == "Y" -o "$is_patch" == "y" ] ; then
	cp lib/upgrade_patch_hpux.sh ${script_home}/${activity_id}/hpux/upgrade.sh
	cp lib/upgrade_patch_linux.sh ${script_home}/${activity_id}/linux/upgrade.sh
        cp lib/upgrade_patch_aix.sh ${script_home}/${activity_id}/aix/upgrade.sh
	cp $patch_bin_hp ${script_home}/${activity_id}/hpux/
        cp $patch_bin_lnx ${script_home}/${activity_id}/linux/
        cp $patch_bin_aix ${script_home}/${activity_id}/aix/
	sed -i 's/@@@PATCH_BINARY@@@/'$(basename $patch_bin_hp)'/g' ${script_home}/${activity_id}/hpux/upgrade.sh
	sed -i 's/@@@PATCH_BINARY@@@/'$(basename $patch_bin_lnx)'/g' ${script_home}/${activity_id}/linux/upgrade.sh
        sed -i 's/@@@PATCH_BINARY@@@/'$(basename $patch_bin_aix)'/g' ${script_home}/${activity_id}/aix/upgrade.sh
	sed -i 's/@@@PATCH_BINARY_HASH@@@/'${patch_bin_hp_hash}'/g' ${script_home}/${activity_id}/hpux/upgrade.sh
	sed -i 's/@@@PATCH_BINARY_HASH@@@/'${patch_bin_lnx_hash}'/g' ${script_home}/${activity_id}/linux/upgrade.sh
        sed -i 's/@@@PATCH_BINARY_HASH@@@/'${patch_bin_aix_hash}'/g' ${script_home}/${activity_id}/aix/upgrade.sh
else
	cp lib/upgrade_hpux.sh ${script_home}/${activity_id}/hpux/upgrade.sh
	cp lib/upgrade_linux.sh ${script_home}/${activity_id}/linux/upgrade.sh
        cp lib/upgrade_aix.sh ${script_home}/${activity_id}/aix/upgrade.sh
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
sed -i 's/@@@PATCH_VERSION@@@/'${patch_id}'/g' ${script_home}/${activity_id}/hpux/upgrade.sh
sed -i 's/@@@PATCH_VERSION@@@/'${patch_id}'/g' ${script_home}/${activity_id}/linux/upgrade.sh
sed -i 's/@@@PATCH_VERSION@@@/'${patch_id}'/g' ${script_home}/${activity_id}/aix/upgrade.sh
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
chown -R apache:apache ${script_home}/log/${activity_id}
chmod a+rx run_upgrade_${activity_id}.sh

echo ""
echo "Good news, we have successfully created the setup for upgrading ControlM Agent from Version $cur_vern. Below are detail."
echo "Create Host DB file and execute binary run_upgrade_${activity_id}.sh to upgrade ControlM Agent."
