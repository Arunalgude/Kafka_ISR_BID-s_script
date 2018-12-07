#!/bin/bash
#set -x
# This Kafka script is only for to find if consumer_offset topic is updated with correct broker ID's for ISR's
# This script is tested for CDH cluster which has parcel based installation.
# Copyright Clairvoyant 2016

echo " Please enter any Zookeeper hostname:- "

read hostname

bash /opt/cloudera/parcels/KAFKA/lib/kafka/bin/zookeeper-shell.sh $hostname:2181 <<< "ls /brokers/ids"| grep '\[*\]' > brokerids.txt

kafka-topics --zookeeper $hostname:2181 --describe | grep -i isr | grep -i topic | cut -f6 > isr.txt


a=(`cat brokerids.txt |  sed 's/[][]//g'| sed -e 's/,//g'| sort -u|uniq -u`)
b=(`cat isr.txt |  sed 's/,/, /g; s/,\s\+/, /g' | sed -e 's/,//g'| sed 's/\Isr://g'| uniq -u | tr ' ' '\n' | sort -u | tr '\n' ' '`)
echo ${a[@]}
echo ${b[@]}

num_a=`echo ${#a[@]}`
num_b=`echo ${#b[@]}`

flag=0

while [ $num_a -ge 0 ] ; do
    flag=0
    num_a=$(($num_a - 1))
    for v in "${b[@]}"; do
                flag=0
               [ ${a[$num_a]} -eq $v ] && break
                #echo " ${a[$num_a]} $v flag=1"
                flag=1
    done

    if [ $flag -eq 1 ]; then
        echo "Warning:-Broker id ${a[$num_a]} is not used in any of ISR..."
        else
        echo "No addtional Broker ids in Broker Id's config found. All OK...:)"
    fi
done

while [ $num_b -ge 0 ] ; do
    flag=0
    num_b=$(($num_b - 1))
    for i in "${a[@]}"; do
                flag=0
               [ ${b[$num_b]} -eq $i ] && break
                #echo " ${b[$num_b]} $i flag=1"
                flag=1
    done

    if [ $flag -eq 1 ]; then
        echo "Critical:- ISR ${b[$num_b]} is not used in any of Broker_Ids.\n... Please check the ISR for topics."
        else
        echo "No addtional entries found in ISR for broker ids...:)"
    fi
done

