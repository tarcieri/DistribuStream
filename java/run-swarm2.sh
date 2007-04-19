#!/bin/sh

#  sh run-swarm2.sh num_clients url

cd build

MINPORT=9000
MAXPORT=MINPORT+$1

for (( port=MINPORT ; port < MAXPORT ; port++ ))
do
  java org.pdtp.PDTPFetch $2 dougie 6000 $port >/dev/null 2> out.$port &
done
