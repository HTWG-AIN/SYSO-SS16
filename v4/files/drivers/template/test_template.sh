#!/bin/bash

make
modinfo template.ko
sudo insmod template.ko
dmesg | grep -i template | tail -1
cat /proc/devices
sudo rmmod template
dmesg | grep -i template | tail -1
