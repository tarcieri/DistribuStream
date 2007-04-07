#!/bin/sh

kill -9 `ps fauxwwww | grep java | grep org.pdtp.PDTPFetch | awk '{ print $2 }'`
