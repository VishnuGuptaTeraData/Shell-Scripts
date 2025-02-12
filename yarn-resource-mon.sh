#!/bin/bash
###############################################################################################################
# Author:   Vishnu Gupta
# Version:  1.0
# Script:  yarn_apps_mon.sh
# Description: This script helps to list out Yarn Applications which consumes more then given threshold Vcores OR Memory
# Usage: sh yarn_mon.sh <vcore_threshold> <memory_threshold_mb>
#        Ex: To list out which yarn job consumes more then 100 vcores OR 300GB
#        sh yarn_mon.sh 100 32070

###################################### Change history ####################################################
# Version: 2.0
# Change description: Added parameter for RM & threshold values for Vcores & Memory
#                     Send email to individual users who consumes more than threshold
#                     Added ALLOCATED-VCORES/MEMORY-PER-CONTAINERS
# Changed by: Mathan Sangunathan
##################################################################################################################3

# Usage
if [ "$#" -lt 2 ]; then
echo "Usage: $0 <vcore_threshold> <memory_threshold_mb>"
exit 1
fi

####To Check the maintenance flag as set or not ############

flag=$(cat /opt/admin/conf/maintenance.txt | sed 's/ //g')

if [ "$flag" == "on" ] || [ "$flag" == "ON" ] ;
then
  echo "Sanity script cannot be executed, since Maintainance is going on"
  exit 0;
else
  echo "Sanity script can be executed"
fi

# An error exit function
error_exit()
{
        if [ $? -ne 0 ]
        then
        echo "$1" | mail -s " ${CLUSTER} - Failed: $1" ${ALERT_MAIL_ID}
        exit 1
        fi
}


# Set environment variable
set -vx
source ~/.bash_profile
WORK_DIR=${DATA_DIR}/YARN-APP
VCORE=$1
MEM=$2

# Create DIR if doesnt exist
if [ ! -d "$WORK_DIR" ]; then
 mkdir -p "$WORK_DIR"
fi

#List the Running Yarn Applications & Dump it into a File
yarn application -list -appStates RUNNING 2>/dev/null | egrep -v 'OlapServer|SpliceMachine' |awk '{print $1}' |grep '^application_'  > $WORK_DIR/yarn-running-app-list-raw.txt
error_exit "$0 - Unable to list Yarn APPS"

cat $WORK_DIR/yarn-running-app-list-raw.txt |grep "application_" > $WORK_DIR/yarn-running-list.txt

if [ -s $WORK_DIR/yarn-running-list.txt ]
then
echo "Runing Application List Generated Successfully, Removing the Raw file "
rm -f $WORK_DIR/yarn-running-app-list-raw.txt
else
echo "Cloudera did not generate the List of Running Yarn Application , Exiting Now... "
exit 1
fi

#Delete OLD Report
rm -f $WORK_DIR/yarn-app-rsrc-usage.csv

echo -n "ApplicationId"  >> $WORK_DIR/yarn-app-rsrc-usage.csv ; echo -n "|" >> $WORK_DIR/yarn-app-rsrc-usage.csv ; echo -n "USER" >> $WORK_DIR/yarn-app-rsrc-usage.csv ;echo -n "|" >> $WORK_DIR/yarn-app-rsrc-usage.csv ; echo -n "JOB_NAME"  >> $WORK_DIR/yarn-app-rsrc-usage.csv ;echo -n "|" >> $WORK_DIR/yarn-app-rsrc-usage.csv ; echo -n "POOL"  >> $WORK_DIR/yarn-app-rsrc-usage.csv ;echo -n "|" >> $WORK_DIR/yarn-app-rsrc-usage.csv ;  echo -n "RUNNING-CONTAINERS" >> $WORK_DIR/yarn-app-rsrc-usage.csv ; echo -n "|" >> $WORK_DIR/yarn-app-rsrc-usage.csv ; echo -n "ALLOCATED-VCORES" >> $WORK_DIR/yarn-app-rsrc-usage.csv ;echo -n "|" >> $WORK_DIR/yarn-app-rsrc-usage.csv ;echo -n "ALLOCATED-MEMORY(MB)"  >> $WORK_DIR/yarn-app-rsrc-usage.csv; echo  -n "|" >> $WORK_DIR/yarn-app-rsrc-usage.csv ; echo -n "ALLOCATED-VCORES-PER-CONTAINERS" >> $WORK_DIR/yarn-app-rsrc-usage.csv; echo  -n "|" >> $WORK_DIR/yarn-app-rsrc-usage.csv ;echo  "ALLOCATED-MEMORY-PER-CONTAINERS(MB)" >> $WORK_DIR/yarn-app-rsrc-usage.csv;


for  apps in `cat $WORK_DIR/yarn-running-list.txt`
do
#curl -k "https://dwbdtest1r1m.wellpoint.com:8090/ws/v1/cluster/apps/$apps/" 2>/dev/null > $WORK_DIR/app-detail.txt
curl -k "${RM_URL}/$apps/" 2>/dev/null > $WORK_DIR/app-detail.txt
appid=`echo $apps`
User=`awk -F "user" '{print $2}' $WORK_DIR/app-detail.txt | awk -F ":" '{print $2}' | awk -F "," '{ gsub(/"/,"" ); print $1}'`
JOBNAME=`awk -F "name" '{print $2}' $WORK_DIR/app-detail.txt | awk -F ":" '{print $2}' | awk -F "," '{ gsub(/"/,"" ); print $1}'`
POOL=`awk -F "queue" '{print $2}' $WORK_DIR/app-detail.txt | awk -F ":" '{print $2}' | awk -F "," '{ gsub(/"/,"" ); print $1}'`
CONTAINERS=`awk -F "runningContainers" '{print $2}' $WORK_DIR/app-detail.txt | awk -F ":" '{print $2}' | awk -F "," '{ gsub(/"/,"" ); print $1}'`
VCORES=`awk -F "allocatedVCores" '{print $2}' $WORK_DIR/app-detail.txt | awk -F ":" '{print $2}' | awk -F "," '{ gsub(/"/,"" ); print $1}'`
MEMORY=`awk -F "allocatedMB" '{print $2}' $WORK_DIR/app-detail.txt | awk -F ":" '{print $2}' | awk -F "," '{ gsub(/"/,"" ); print $1}'`
ALLOCATED_VCORES_PER_CONTAINERS=$((VCORES/CONTAINERS))
ALLOCATED_MEMORY_PER_CONTAINERS=$((MEMORY/CONTAINERS))
echo "$appid|$User|$JOBNAME|$POOL|$CONTAINERS|$VCORES|$MEMORY|$ALLOCATED_VCORES_PER_CONTAINERS|$ALLOCATED_MEMORY_PER_CONTAINERS" >> $WORK_DIR/yarn-app-rsrc-usage.csv
done

#Filter Applications using More then 100 Vcores OR 300 GB MEMORY
awk -F "|" -v vcore=$VCORE -v mem=$MEM '{if (($6 > vcore) || ($7 >= mem)) { print } }' $WORK_DIR/yarn-app-rsrc-usage.csv > $WORK_DIR/Yarn-App-$DATE.txt

cat $WORK_DIR/Yarn-App-$DATE.txt |grep -v "ALLOCATED-VCORES|ALLOCATED-MEMORY" > $WORK_DIR/Data-Test.txt

if [ -s  $WORK_DIR/Data-Test.txt ]
then
echo "Genarated File has data , Send the Alert "
rm -f  $WORK_DIR/Data-Test.txt

# Convert text to csv
cat $WORK_DIR/Yarn-App-"$DATE".txt | tr '|' ',' > $WORK_DIR/Yarn-App-"$DATE".csv

# Send email report
if [ -s $WORK_DIR/Yarn-App-"$DATE".txt ];then cat $WORK_DIR/Yarn-App-"$DATE".txt | mailx -s "${CLUSTER} - ALERT:Yarn Application which consumes more than $VCORE VCORE OR $MEM MB MEM" -a $WORK_DIR/Yarn-App-"$DATE".csv ${ALERT_MAIL_ID}; fi
else
echo "No Yarn App Consuming more than the Threshold Limit , All Good.."
fi

# Send email alert to individual users
for APPS in `cat $WORK_DIR/Yarn-App-"$DATE".txt | sort | egrep -v "hive|src|ApplicationId" | awk -F"|" '{if (($8 >= 5) || ($9 >= 30720)) { print } }'`
do
echo -e "\nHello,\n\nThis is an automatically-generated notification from Hadoop Team\n\nFollowing Yarn Application is consuming more than 4 Vcores Per Container OR 30270MB(30GB) Memory.Please refer the below user guide to optimize the job.\n\nSpark Developmental Best Practices: https://confluence.anthem.com/display/ABD/SPARK+-++User+Guide\n\nApplicationId|USER|JOB_NAME|POOL|RUNNING-CONTAINERS|ALLOCATED-VCORES|ALLOCATED-MEMORY|ALLOCATED_VCORES_PER_CONTAINERS|ALLOCATED_MEMORY_PER_CONTAINERS\n$APPS" | mail -s "ACTION REQUIRED: ${CLUSTER} - Yarn Application which consumes more resources per Container" -r "bigdatahadoopsupport@anthem.com" "`echo $APPS | awk -F"|" '{print $2}'`@wellpoint.com"
done

# Delete logs more than 7 days
find ${WORK_DIR} -mtime +5 -type f -exec rm -f {} \;
