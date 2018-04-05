#!/bin/bash
#==================================================================================================================================
# Usage  : Script to uninstall and archive a perticular scenario.
# Version: 1.0
# Date   : 21-03-2018
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

[ ! -d ${script_home}/ARCHIVE/ ] && mkdir -p ${script_home}/ARCHIVE/
[ $? -ne 0 ] && ( echo "ERROR: Unable to create archive home."; exit 1)
mkdir -p ${script_home}/ARCHIVE/${scenro}_${today_dt}
[ $? -ne 0 ] && ( echo "ERROR: Unable to create scanario archive home."; exit 1)


mv ${script_home}/run_upgrade_${scenro}.sh ${script_home}/ARCHIVE/${scenro}_${today_dt}/

mkdir -p ${script_home}/ARCHIVE/${scenro}_${today_dt}/log
mv ${script_home}/log/${scenro} ${script_home}/ARCHIVE/${scenro}_${today_dt}/log/${scenro}

mkdir -p ${script_home}/ARCHIVE/${scenro}_${today_dt}/${scenro}/aix/ ${script_home}/ARCHIVE/${scenro}_${today_dt}/${scenro}/linux/ ${script_home}/ARCHIVE/${scenro}_${today_dt}/${scenro}/hpux/
mv ${script_home}/${scenro}/aix/upgrade.* ${script_home}/ARCHIVE/${scenro}_${today_dt}/${scenro}/aix/
mv ${script_home}/${scenro}/hpux/upgrade.* ${script_home}/ARCHIVE/${scenro}_${today_dt}/${scenro}/hpux/
mv ${script_home}/${scenro}/linux/upgrade.* ${script_home}/ARCHIVE/${scenro}_${today_dt}/${scenro}/linux/

cd ${script_home}/ARCHIVE/
tar -zcvf ${scenro}_${today_dt}.tar.gz ${scenro}_${today_dt} 
[ $? -eq 0 ] && ( rm -rf ${script_home}/${scenro} ; rm -rf ${script_home}/ARCHIVE/${scenro}_${today_dt} )

echo "Completed uninstalling."
