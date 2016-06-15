#!/bin/sh

MOD_NAME="mynull"

echo
echo "** Module info"
modinfo $MOD_NAME.ko

echo
echo "** Loading module..."
insmod $MOD_NAME.ko
dmesg | grep -i $MOD_NAME | tail -1

echo
echo "** /proc/devices"
cat /proc/devices | grep -i $MOD_NAME

echo
echo "** Access tests..."
MAJOR=$(cat /proc/devices | grep -i $MOD_NAME | sed -r 's/^ *([0-9]+) .*$/\1/')
mknod /dev/${MOD_NAME}_major0 c $MAJOR 0
/usr/bin/access -d /dev/${MOD_NAME}_major0 -w

echo
echo "** Removing module..."
rmmod $MOD_NAME
dmesg | grep -i $MOD_NAME | tail -1
