create database IF NOT EXISTS capacity_report
COMMENT 'DB to Monitor Space Utilization for Diff Projects '
LOCATION '/ts/hdfsdata/vs2/rep/rsrc/no_phi/no_gbd/r000/work/';

create  table IF NOT EXISTS capacity_report.Edge_Node_Prj_Space_Rpt_${MONTH} ( MONITOR_DT DATE , Program varchar(40), Project varchar(40),EdgeNodeDirPath varchar(100),EdgeNodeUsage varchar(20) )
COMMENT ' Table To Monitor Test Edgenode Project Specific Dir. Space Usage'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
STORED AS TEXTFILE ;

LOAD DATA INPATH '/user/af39843/dataE_FINAL.csv' OVERWRITE INTO TABLE capacity_report.Edge_Node_Prj_Space_Rpt_${MONTH};


create table IF NOT EXISTS capacity_report.HDFS_Capacity_Report_${MONTH}( MONITOR_DT DATE, HDFS_Capacity varchar(40),DFS_USED varchar(40),DFS_AVIALABLE varchar(40),DFS_USABLE varchar(40))
COMMENT 'Table To Capture HDFS Space Utilization '
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
STORED AS TEXTFILE ;

LOAD DATA INPATH '/user/af39843/dataH.csv' OVERWRITE INTO TABLE capacity_report.HDFS_Capacity_Report_${MONTH};
