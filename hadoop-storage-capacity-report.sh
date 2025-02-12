set -vx
TS=`date +"%Y-%m-%d %H:%M:%S"`
RPT_MTH=`date +"%m%Y"`
WORK_DIR=/home/af39843
############################################# EXTRACTING THE PROJECT SPECIFIC  DIRECTORY NAMES ########################################################
#rm -f $WORK_DIR/test.txt
#rm -f $WORK_DIR/dir-name-tmp.txt
#sudo $WORK_DIR/extract-prj-dir-names.sh
#sudo chmod 644 $WORK_DIR/dir-name-tmp.txt
sudo $WORK_DIR/extract-all-prj-dir.sh

#sudo chmod 644 $WORK_DIR/dir-name-tmp.txt

########################################################### EDGE NODE TEXT PROCESSING CODE ###########################################################
rm -f $WORK_DIR/dataE.csv

for DIR in `cat $WORK_DIR/dir-name.txt`
do
#sudo du -s -h $DIR |awk -F '[/ ]' '{print $6 " " $1"/"$2"/"$3"/"$4"/"$5 " "  $5}'|awk -F " " '{print $3 " " $2 " " $1}'|sed -e 's/ /,/g' > $WORK_DIR/dataE.csv
sudo du -s -h $DIR |awk -F '[/ ]' '{print $5 "," $6 "," "/" $2"/"$3"/"$4"/"$5"/"$6 "," $1}' >> $WORK_DIR/dataE.csv
done

{
if [ ! -f $WORK_DIR/dataE.csv ];
then
  echo "dataE.csv File Not found,Exiting Now !"
  exit 0
fi
}
#rm -f $WORK_DIR/dir-name-tmp.txt

####################################################### APPEND DATE COLUMN INTO THE DATA FILE ###########################################################

#awk 'BEGIN{"date +%Y-%m-%d"|getline d}NR==0{$3=$3" =="}NR>0{$3=$3","d}1' $WORK_DIR/dataE.csv |tr -s " " > $WORK_DIR/dataE_FINAL.csv

################################################ OLD LOGIC TO MOVE DATE COLUMN DISPLAYED AS FIRST CLOUMN ################################################


#awk 'BEGIN{"date +%Y-%m-%d"|getline d}NR==0{$3=$3" =="}NR>0{$3=$3","d}1' $WORK_DIR/dataE.csv | > $WORK_DIR/dataE_FINAL.csv

################################ New Logic To Add Program, Project Name Fields and Date appear as First Column to Final Data File #######################


awk 'BEGIN{"date +%Y-%m-%d"|getline d}NR==0{$3=$3" =="}NR>0{$3=$3","d}1' dataE.csv |tr -s " " |awk -F "," '{print $5 "," $1 "," $2 "," $3 "," $4}' > $WORK_DIR/dataE_FINAL.csv

{
if [ ! -f $WORK_DIR/dataE_FINAL.csv ];
then
  echo "No EDGE NODE PROJECT SPACE Data File to Load , Exiting Now !"
  exit 0
fi
}

rm -f $WORK_DIR/dataE.csv

hdfs dfs -rm /user/af39843/dataE_FINAL.csv

hdfs dfs -put $WORK_DIR/dataE_FINAL.csv /user/af39843/

#hdfs dfs -test -e /user/af39843/dataE_FINAL.csv

#var1=`echo $?`
#{
#if [ $var1 -ne 0 ];then
 #  echo "Data File Did not get Copied to HDFS, Please Push it manually and Load "
#else
#continue
#fi
#}

hdfs dfs -chmod 755 /user/af39843/dataE_FINAL.csv

###################################################### OLD  HDFS CAPACITY MONITORING TEXT PROCESSING CODE ########################################################

#hdfs dfsadmin -report |head -4 |tail -3 |head -2 |awk 'ORS=NR%2?" ":"\n"' |cut -d " " -f4,5,9,10 |sed -e 's/(//g' -e 's/)//g' |awk -F " " '{print $1 " " $2 "," $3 " " $4 "," $3/3 " " $4}' > $WORK_DIR/dataH.csv

##################################################### New Logic to Include Date as First Column #################################################################

hdfs dfsadmin -report |head -4 |tail -3 |awk 'ORS=NR%3?" ":"\n"' |sed -e 's/(//g' -e 's/)//g' |awk -F " " '{print $3/1099511627776","$13/1099511627776","$8/1099511627776","$8/3/1099511627776}' |sed -e 's/,/ TB,/g' |awk 'BEGIN{"date +%Y-%m-%d"|getline d}NR==0{$4=$4" =="}NR>0{$4=$4","d}1' |awk -F "," '{print $5","$1","$2","$3","$4}' |sed -e 's/$/ TB/g' > $WORK_DIR/dataH.csv

{
if [ ! -f  $WORK_DIR/dataH.csv ];
then
  echo " No HDFS CAPACITY datafile to Load , Exiting Now "
  exit 0
fi
}

hdfs dfs -rm /user/af39843/dataH.csv

hdfs dfs -put $WORK_DIR/dataH.csv /user/af39843

#hdfs dfs -test -e /user/af39843/dataH.csv

#var1=`echo $?`
#{
#if [ $var1 -ne 0 ];then
#   echo "File dataH.csv Did not get Copied to HDFS, Please Push it manually and Load "
#else
#continue
#fi
#}

hdfs dfs -chmod 755 /user/af39843/dataH.csv

rm -f $WORK_DIR/dir-name-tmp.txt
rm -f $WORK_DIR/test.txt

############################################################## OBJECT CREATION IN HIVE ##########################################################################

beeline -u 'jdbc:hive2://dwbdtest1r2m3.wellpoint.com:2181,dwbdtest1r1m.wellpoint.com:2181,dwbdtest1r2m.wellpoint.com:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2' -f $WORK_DIR/HDFS_Capacity_Report.hql --hivevar MONTH=$RPT_MTH

beeline -u 'jdbc:hive2://dwbdtest1r2m3.wellpoint.com:2181,dwbdtest1r1m.wellpoint.com:2181,dwbdtest1r2m.wellpoint.com:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2' -e "select monitor_dt,program,project,edgenodedirpath,edgenodeusage from capacity_report.edge_node_prj_space_rpt_082017" --outputformat=tsv > $WORK_DIR/edgenode-rpt.csv

cat $WORK_DIR/edgenode-rpt.csv |sed -e 's/+//g' -e 's/-//g' -e 's/|//g' |tr -s " " |sed -e 's/ /,/g' > $WORK_DIR/EdgeNode-SpaceReport.csv

if [ -s $WORK_DIR/EdgeNode-SpaceReport.csv ]
then
echo "Please find the Edgenode Project Specific Space Usage Report Attached to this Email" |mailx -s "Project Space Usage Report on  Edge Node - TEST Env" -a $WORK_DIR/EdgeNode-SpaceReport.csv "vishnu.gupta@anthem.com"
else
exit 0
fi