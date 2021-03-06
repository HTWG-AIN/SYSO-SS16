#!/bin/sh

MOD_NAME="kthread"

echo
echo "** Module info"
modinfo $MOD_NAME.ko

echo
echo "** Loading module..."
modprobe $MOD_NAME
dmesg | grep -i $MOD_NAME | tail -1

echo
echo "** /proc/devices"
cat /proc/devices | grep -i $MOD_NAME

echo
echo "** sleeping for 5 seconds"
sleep 5s


echo
echo "** Removing module..."
rmmod $MOD_NAME
dmesg | grep -i $MOD_NAME | tail -1
