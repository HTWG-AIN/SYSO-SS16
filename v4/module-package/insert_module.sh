#!/bin/bash

# NOTE: not needed when using BR2_EXTERNAL

if [ $# -ne 2 ]; then
    echo "Usage: $0 {buildroot_dir} {package_dir}"
    exit 1
fi

BUILDROOT_DIR=$(readlink -f $1)
MODULE_PACKAGE_DIR=$(readlink -f $2)

ln -s "$MODULE_PACKAGE_DIR" "$BUILDROOT_DIR/package/syso"
