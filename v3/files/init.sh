#!/bin/sh

echo "Making directories"
chown -R root:root /

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

echo "Mounting /dev/pts"
mkdir /dev/pts
mount -t devpts devpts /dev/pts

/etc/init.d/S40udhcpc start
#/etc/init.d/S50dropbear start
start-stop-daemon -S -q -p /var/run/dropbear.pid -x /usr/sbin/dropbear -- -R

/bin/systeminfo

exec /bin/sh
