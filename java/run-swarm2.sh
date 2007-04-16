#!/bin/sh

#  sh run-swarm2.sh num_clients url

cd build

MINPORT=7000
MAXPORT=MINPORT+$1

for (( port=MINPORT ; port < MAXPORT ; port++ ))
do
  java org.pdtp.PDTPFetch $2 dev.clickcaster.com 6000 $port &> out.$port &
done
