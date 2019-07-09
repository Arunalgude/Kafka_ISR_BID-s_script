#!/bin/bash
#set -x




#Zookeeper List
KAFKA_DIR=`ps -aef | grep "KAFKA_BROKER" | grep -v grep  | awk -F"-Dkafka.logs.dir=" '{print $2}' | awk '{print $1}'`
ZK_LIST=`cat $KAFKA_DIR/kafka.properties | grep "zookeeper.connect" | awk -F"=" '{print $2}'`

#List the broker ids.

broker_ids=$(kafka-run-class org.apache.zookeeper.ZooKeeperMain -server $ZK_LIST  2>/dev/null <<< "ls /brokers/ids" | tail -1|sed 's/[][]//g'| sed -e 's/,//g')


#list the ISRs
full_isr=$(kafka-topics --zookeeper $ZK_LIST --describe 2>/dev/null | grep -i isr | grep -i topic| sed 's/Topic/^Topic/g')

full_isr=$(echo "$full_isr^" | sed 's/^//')

while read -d"^" var; do
var=$(echo $var | sed 's/^//g')
    temp_isr=$(echo $var | egrep -o "Isr: [0-9,]*?" | cut -d ':' -f2)
    for var_isr in $(echo $temp_isr | sed 's/,/ /g');do
        flag=0
        for var_lookup in $broker_ids;do
            if [[ $var_isr -eq $var_lookup ]];then
                flag=1; break
            fi
        done
        if [[ $flag -ne 1 ]];then
            report_client="${report_client}Current Broker Id's in Kafka::${broker_ids}\n Invalid Broker IDs found in Isr::\n${var}\n"
        fi
    done
done <<< $(echo $full_isr)

if [[ -z $report_client ]];then
   echo "No Invalid Broker IDs found in ISR" | mailx -s "  Kafka_Offsets:Kafka offset Test" user@test.com
else
   echo -e "$report_client" | mailx -s " Kafka_Offsets:Kafka offset Test" user@test.com
fi
