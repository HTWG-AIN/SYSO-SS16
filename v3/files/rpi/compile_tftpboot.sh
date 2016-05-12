#!/bin/sh

#Create init script
mkimage -A arm -O linux -T script -C none -d tftpboot.scr.txt tftpboot.scr
