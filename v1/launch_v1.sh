#!/bin/bash

if [ $# -ne 2 ]; then
	echo "Usage: $0 <kernel> <initramfs>"
	exit 0
fi

ARCH="i386"
KERNEL="$1"
INITRAMFS="$2"
qemu-system-$ARCH -kernel "$KERNEL" -initrd "$INITRAMFS" -curses
