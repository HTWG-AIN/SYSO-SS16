#!/bin/sh

MOD_NAME="buf"

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
echo "** Access tests..."
MAJOR=$(cat /proc/devices | grep -i $MOD_NAME | sed -r 's/^ *([0-9]+) .*$/\1/')
mknod /dev/${MOD_NAME}_major0 c $MAJOR 0

/usr/bin/access -d /dev/${MOD_NAME}_major0 -b

#
#	function readTest {
#		echo "step 1: reading"
#		/usr/bin/access -d /dev/${MOD_NAME}_major0 -r -s
#		echo "    finished step 1"
#
#	}
#
#	readTest &
#	READINGTASK=$!
#
#	sleep 1
#	echo "step 2: writing"
#	/usr/bin/access -d /dev/${MOD_NAME}_major0 -w -s
#	echo "    finished step 2"
#	sleep 2
#
#
#	echo "step 3: writing, filling up buffer"
#	/usr/bin/access -d /dev/${MOD_NAME}_major0 -w 
#	echo "    finished step 3"
#
#	function writeTest {
#		echo "step 4: writing, awaiting buffer space"
#		/usr/bin/access -d /dev/${MOD_NAME}_major0 -w -s 
#		echo "    finished step 4"
#	}
#	writeTest &
#	WRITINGTASK=$!
#
#
#	sleep 1
#
#	echo "step 5: reading, creating space in buffer"
#	/usr/bin/access -d /dev/${MOD_NAME}_major0 -w 
#	echo "    finished step 5"
#
#	sleep 3

# Kill tasks
kill $READINGTASK >/dev/null 2>&1
kill $WRITINGTASK >/dev/null 2>&1


echo
echo "** Removing module..."
rmmod $MOD_NAME
dmesg | grep -i $MOD_NAME | tail -1
