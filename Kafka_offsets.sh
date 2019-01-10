#!/bin/bash

#following script is for checking the kafka offsets are getting updated with correct broker ids upon restart of KAFKA service. 
#Run script as sudo user.



KAFKA_DIR=`ps -aef | grep "KAFKA_BROKER" | grep -v grep  | awk -F"-Dkafka.logs.dir=" '{print $2}' | awk '{print $1}'`
ZK_LIST=`cat $KAFKA_DIR/kafka.properties | grep "zookeeper.connect" | awk -F"=" '{print $2}'`
  
echo "ZK_LISt : $ZK_LIST..."


kafka-run-class org.apache.zookeeper.ZooKeeperMain -server $ZK_LIST <<< "ls /brokers/ids"| grep '\[*\]' > brokerids.txt


kafka-topics --zookeeper $ZK_LIST --describe | grep -i isr | grep -i topic | cut -f6 > isr.txt

a=(`cat brokerids.txt |  sed 's/[][]//g'| sed -e 's/,//g'|uniq`)
b=(`cat isr.txt |  sed 's/,/, /g; s/,\s\+/, /g' | sed -e 's/,//g'| sed 's/\Isr://g'| uniq  | tr ' ' '\n' | sort -u | tr '\n' ' '`)

#echo ${a[@]}  #Print Broker ID's ARRAY
#echo ${b[@]}  #Print ISR ID's ARRAY

num_a=`echo ${#a[@]}`
num_b=`echo ${#b[@]}`

#Compare the Borker ID's with ISR's
flag=0

while [ $num_a -ge 0 ] ; do
    flag=0
    num_a=$(($num_a - 1))
    for v in "${b[@]}"; do
                flag=0
               [ ${a[$num_a]} -eq $v ] && break
               # echo " ${a[$num_a]} $v flag=1"
                flag=1
    done


    if [ $flag -eq 1 ]; then
        echo "Broker id ${a[$num_a]} is not used in any of of ISR..." | mail -s "KAFKA_OFFSET_STATUS" -aFrom:Arun\<example@gmail.com\> someone@mail.com
    else
        echo "No addtional Broker ids in Broker Id's config found. All OK...:)" | mail -s "KAFKA_OFFSET_STATUS" -aFrom:Arun\<example@gmail.com\> someone@mail.com
    fi
done

#Compare the ISR's array with Broker ID's.
while [ $num_b -ge 0 ] ; do
    flag=0
    num_b=$(($num_b - 1))
    for i in "${a[@]}"; do
                flag=0
               [ ${b[$num_b]} -eq $i ] && break
               # echo " ${b[$num_b]} $i flag=1"
                flag=1
    done

    if [ $flag -eq 1 ]; then
        echo "ISR ${b[$num_b]} is not used in any of of Broker_Ids..." | mail -s "KAFKA_OFFSET_STATUS" -aFrom:Arun\<example@gmail.com\> someone@mail.com
    else
        echo "No addtional entries found in ISR for broker ids...:)" | mail -s "KAFKA_OFFSET_STATUS" -aFrom:Arun\<example@gmail.com\> someone@mail.com
    fi
done

