#!/bin/bash

# Constants
OUTPUT="stdout_1.log"
OUTPUT_ERR="errorout_1.log"
VERSION="4.2.3"
CORES=$(cat /proc/cpuinfo | grep processor | wc -l)
TOOLCHAIN_PATH="/group/SYSO_WS1516/crosstool-ng/tmp/armv6j-rpi-linux-gnueabihf/bin/"

# Environment variables
export PATH="$TOOLCHAIN_PATH:$PATH"
export ARCH="arm"
export CROSS_COMPILE="armv6j-rpi-linux-gnueabihf-"
export CC="ccache gcc"

function download_sources {
    echo "* Downloading kernel version $VERSION..."
    cd "$TARGET"
    if [ ! -d "linux-$VERSION" ]; then
        # Download the kernel if necessary
        test -f "linux-$VERSION.tar.xz" || wget "https://kernel.org/pub/linux/kernel/v4.x/linux-$VERSION.tar.xz"
        #test -f "linux-$VERSION.tar.sign" || wget "https://kernel.org/pub/linux/kernel/v4.x/linux-$VERSION.tar.sign"
        #unxz "linux-$VERSION.tar.xz"
        #gpg --verify "linux-$VERSION.tar.sign" || \
        #   echo "Bad signature. Aborting." && \
        #   rm -rf "linux-$VERSION.tar" && \
        #   exit 1
        test -d "linux-$VERSION" && rm -rf "linux-$VERSION"
        xz -cd "linux-$VERSION.tar.xz" | tar xvf -
        #rm "linux-$VERSION.tar"
    fi
}

function patch_sources {
    echo "* Patching sources..."
}

function copy_sources {
    echo "* Copying GitLab sources..."
}

function compile_sources {
    echo "* Compiling sources..."
    cd "$TARGET"
    cp files/kernel_config "linux-$VERSION"/.config
    cd "linux-$VERSION"

    # Compile
    make -j $CORES
}

function start_qemu {
    echo "* Starting qemu..."
}

function usage {
    echo "Usage: $0 [--dn ][--pa ][--cp ][--co ][--qe]
 
  --dn                  download sources
  --pa                  patch sources
  --cp                  copy GitLab sources
  --co                  compile sources
  --qe                  start qemu and a windows terminal to the serial port
  -h, --help            show this help page, then exit
"
    
    exit 0
}

if [ $# -lt 1 ]; then
    usage
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR/.."
# echo "$PWD"
if [ ! -d "target" ]; then
    echo "* Creating target folder"
    mkdir target
fi
cd target
TARGET=$(pwd)
echo "* Target output directory: $TARGET"

while [ "$1" != "" ]; do
    case $1 in
        --dn )                  download_sources
                                ;;
        --pa )                  patch_sources
                                ;;
        --cp )                  copy_sources
                                ;;
        --co )                  compile_sources
                                ;;
        --qe )                  start_qemu
                                ;;
        -h | --help )           usage
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done
