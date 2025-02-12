set -vx
############ Get The NameService Name ################################
NS=`hdfs getconf -confKey dfs.nameservices`
############ Get Destination NN HA ####################################
DEST_NN_HA=`hdfs getconf -confKey dfs.ha.namenodes.$NS`
NN1=`echo $DEST_NN_HA |cut -d"," -f1`
NN2=`echo $DEST_NN_HA |cut -d"," -f2`
############# Get STATE for Each NN ###################################
NN96=`hdfs haadmin -getServiceState $NN1`
NN157=`hdfs haadmin -getServiceState $NN2`
############ Get NN RPC Address of Active NN ###########################
if [ "$NN96" == "active" ];
then
    echo " $NN1 is the Active NameNode , Get the RPC address Now "
    hdfs getconf -confKey dfs.namenode.rpc-address.$NS.$NN1 > /home/af39843/HData-Rep/active-nn.txt
else
    echo " $NN2 is the Active NameNode , Get the RPC address Now "
    hdfs getconf -confKey dfs.namenode.rpc-address.$NS.$NN2 > /home/af39843/HData-Rep/active-nn.txt

fi
