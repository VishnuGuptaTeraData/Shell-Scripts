#set -vx

WORK_DIR=/home/af39843/HDFS-Q

################################################## List All the Users HDFS Home Directory ##################################
hdfs dfs -ls /user | sed '1d;s/  */ /g' | cut -d\  -f8 |grep -vwi "impala\|datameer\|hbase\|hive\|hue\|oozie\|spark\|splice\|hdfs\|history\|sdc\|srcpcenterb\|yarn" |grep -v '/user/src*' > $WORK_DIR/hdfs-users-list.txt
#hdfs dfs -ls /user | sed '1d;s/  */ /g' | cut -d\  -f8 > /$WORK_DIR/hdfs_quota_validation.txt
############################################## HDFS Quota Assigment ###############################
#cat $WORK_DIR/hdfs-users-list.txt |grep 'af39843' > $WORK_DIR/sample-user.txt

#for Dir in `cat $WORK_DIR/sample-user.txt`
#for Dir in `cat $WORK_DIR/hdfs-users-list.txt`
for Dir in `cat $WORK_DIR/hdfs-users-list.txt`
do
Quota_V=`hadoop fs -count -q $Dir |awk -F " " '{printf $3}'`
echo "Dierctoy $Dir has Space Quota Set to :- " $Quota_V
  if [ $Quota_V = none ];
    then
     echo -e "Directory \e[31m$Dir Does Not Have Any Space Quota Assigned \e[0m" >> $WORK_DIR/no-quota-users-list.txt
     hdfs dfsadmin -setSpaceQuota 30g $Dir
     echo -e "Directory \e[32m$Dir Has been Assigned Space Quota of 30 GB \e[0m"
    else
     echo -e "Directory \e[32m$Dir Has Space Quota of $Quota_V Assigned Already \e[0m"
  fi
done
