#!/bin/sh

echo "Making directories"
mkdir -p /proc
mkdir -p /sys
mkdir -p /etc
mkdir -p /dev

echo "Mounting /proc filesystem"
mount -t proc proc /proc

echo "Mounting /sys"
mount -t sysfs sysfs /sys

echo "Mounting /dev"
mount -t devtmpfs dev /dev

#echo "Populating /dev directory"
#mknod /dev/console c 5 1
#mknod /dev/null c 1 3
#mknod /dev/zero c 1 5
#mknod /dev/ram c 1 1
#mknod /dev/systty c 4 0
#mknod /dev/tty1 c 4 1
#mknod /dev/tty2 c 4 2
#mknod /dev/tty3 c 4 3
#mknod /dev/tty4 c 4 4
#mknod /dev/urandom c 1 9
#mknod /dev/random c 1 8

echo "Mounting /dev/pts"
mkdir /dev/pts
mount -t devpts devpts /dev/pts

echo "Starting udhcpc"
udhcpc

echo "Starting telnetd"
telnetd

/bin/systeminfo

exec /bin/sh
