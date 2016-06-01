#!/bin/sh

MOD_NAME="openclose"

echo
echo "** Module info"
modinfo $MOD_NAME.ko

echo
echo "** Loading module..."
sudo insmod $MOD_NAME.ko
dmesg | grep -i $MOD_NAME | tail -1

echo
echo "** /proc/devices"
cat /proc/devices

echo
echo "** Removing module..."
sudo rmmod $MOD_NAME
dmesg | grep -i $MOD_NAME | tail -1
