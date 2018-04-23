#!/bin/bash
#==================================================================================================================================
# Usage  : Script to uninstall and archive a perticular scenario.
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
today_dt=$(date +%F-%H-%M)

if [ ! -f ${script_home}/run_upgrade_${scenro}.sh -o ! -d ${script_home}/${scenro} -o ! -d ${script_home}/log/${scenro} ] ; then
        echo "ERROR: Migration scanario does not exists!!!"
        exit 1
fi

echo "Uninstalling, the complete audit will be archived in directory ${script_home}/ARCHIVE/${scenro}_${today_dt}.tar.gz."
echo "Creating archive home."
if [ ! -d ${script_home}/ARCHIVE/ ] ; then
	mkdir -p ${script_home}/ARCHIVE/
	if [ $? -ne 0 ] ; then
		echo "ERROR: Unable to create archive home."
		exit 1
	fi
fi
mkdir -p ${script_home}/ARCHIVE/${scenro}_${today_dt}
if [ $? -ne 0 ] ; then
	echo "ERROR: Unable to create scanario archive home."
	exit 1
fi

echo "Archiving scenario execution script..."
mv ${script_home}/run_upgrade_${scenro}.sh ${script_home}/ARCHIVE/${scenro}_${today_dt}/

mkdir -p ${script_home}/ARCHIVE/${scenro}_${today_dt}/log
if [ -d ${script_home}/log/${scenro} ] ; then
	echo "Archiving scenario logs..."
	mv ${script_home}/log/${scenro} ${script_home}/ARCHIVE/${scenro}_${today_dt}/log/${scenro}
fi

mkdir -p ${script_home}/ARCHIVE/${scenro}_${today_dt}/DB/
if [ -d ${script_home}/DB/${scenro} ] ; then
	echo "Archiving scenario DB..."
	mv ${script_home}/DB/${scenro} ${script_home}/ARCHIVE/${scenro}_${today_dt}/DB/${scenro}
fi

if [ -d ${script_home}/${scenro} ] ; then
	echo "Archiving scenario web contents..."
	mkdir -p ${script_home}/ARCHIVE/${scenro}_${today_dt}/${scenro}/aix/ 
	mkdir -p ${script_home}/ARCHIVE/${scenro}_${today_dt}/${scenro}/hpux/
        mkdir -p ${script_home}/ARCHIVE/${scenro}_${today_dt}/${scenro}/linux/
	mv ${script_home}/${scenro}/aix/upgrade.* ${script_home}/ARCHIVE/${scenro}_${today_dt}/${scenro}/aix/
	mv ${script_home}/${scenro}/hpux/upgrade.* ${script_home}/ARCHIVE/${scenro}_${today_dt}/${scenro}/hpux/
	mv ${script_home}/${scenro}/linux/upgrade.* ${script_home}/ARCHIVE/${scenro}_${today_dt}/${scenro}/linux/
fi

echo "Completing archive creation..."
cd ${script_home}/ARCHIVE/
tar -zcvf ${scenro}_${today_dt}.tar.gz ${scenro}_${today_dt} 
if [ $? -eq 0 ] ; then 
	echo "Clearing filesystem..."
	rm -rf ${script_home}/${scenro}
	rm -rf ${script_home}/ARCHIVE/${scenro}_${today_dt}
fi

echo "Completed uninstalling."
