#!/bin/sh

cd build

for port in 7000 7001 7002 7003 7004 7005 7006 7007 7008 7009 7010 7011 7012 7013 7014 7015 7016 7017 7018 7019 7020; do
  java org.pdtp.PDTPFetch $1 dev.clickcaster.com 6000 $port &> out.$port &
done
