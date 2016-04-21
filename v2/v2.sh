#!/bin/bash

# Constants
OUTPUT="stdout_1.log"
OUTPUT_ERR="errorout_1.log"
KERNEL_VERSION="4.2.3"
BUSYBOX_VERSION="1.24.2"
CORES=$(cat /proc/cpuinfo | grep processor | wc -l)
TOOLCHAIN_PATH="/group/SYSO_WS1516/crosstool-ng/tmp/armv6j-rpi-linux-gnueabihf/bin/"

# Environment variables
export PATH="$TOOLCHAIN_PATH:$PATH"
export ARCH="arm"
export CROSS_COMPILE="armv6j-rpi-linux-gnueabihf-"
export CC="ccache gcc"

function download_kernel {
    echo "-> Downloading kernel version $VERSION..."
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

        echo "-> Unpacking kernel..."
        xz -cd "linux-$VERSION.tar.xz" | tar xvf -
        #rm "linux-$VERSION.tar"
    fi
}

function download_busybox {
    echo "-> Downloading busybox version $BUSYBOX_VERSION..."
    cd "$TARGET"
    if [ ! -d "busybox-$BUSYBOX_VERSION" ]; then
        test -f "busybox-$BUSYBOX_VERSION.tar.bz2" || wget "http://busybox.net/downloads/busybox-$BUSYBOX_VERSION.tar.bz2"
        test -d "busybox-$BUSYBOX_VERSION" && rm -rf "busybox-$BUSYBOX_VERSION"

        echo "-> Unpacking busybox..."
        tar xjvf "busybox-$BUSYBOX_VERSION.tar.bz2"
    fi
}

function download_sources {
    echo "* Downloading sources..."
    download_kernel
    download_busybox
}

function patch_sources {
    echo "* Patching sources..."
}

function copy_sources {
    echo "* Copying GitLab sources..."
}

function create_initramfs {
    echo "* Creating initramfs..."
    cd "$TARGET"
    mkdir initramfs
    cd initramfs

    echo "-> Creating directory tree..."
    mkdir -p dev sbin bin usr/bin etc var tmp
    cd bin
    #currently in target/initramfs/bin

    echo "-> Compiling systeminfo..."
    ${CROSS_COMPILE}gcc --static ../../files/systeminfo.c -o systeminfo

    echo "-> Copying and linking busybox..."
    cp "$TARGET/busybox" busybox
    chmod 755 busybox
    for bin in mount echo ls cat ps dmesg sysctl sh sleep; do
        ln -s busybox $bin
    done
    cd ..

    echo "-> Using provided init file..."
    cp "$TARGET/files/init.sh" init
    chmod 755 init

    echo "-> Packaging initramfs files into initramfs.cpio..."
    find . | cpio -H newc -o > ../initramfs.cpio

    echo "-> Cleaning up"
    cd ..
    rm -rf initramfs
}

function compile_kernel {
    echo "-> Compiling kernel..."
    cd "$TARGET"
    cp files/kernel_config "linux-$VERSION"/.config
    cd "linux-$VERSION"
    make -j $CORES
}

function compile_busybox {
    echo "-> Compiling busybox..."
    cd "$TARGET"
    cp files/busybox_config "busybox-$BUSYBOX_VERSION"/.config
    cd "busybox-$BUSYBOX_VERSION"
    make -j $CORES
}

function compile_sources {
    echo "* Compiling sources..."
    compile_kernel
    compile_busybox
}

function start_qemu {
    echo "* Starting QEMU..."
    cd "$TARGET"
    QEMU_ARCH="arm"
    # TODO: versatileab?
    MACHINE="versatilepb"
    # TODO: which cpu?
    CPU="??"
    qemu-system-$QEMU_ARCH \
        -machine "$MACHINE" \
        -cpu "$CPU" \
        -kernel "linux-$VERSION/arch/$ARCH/boot/zImage" \
        -initrd "initramfs.cpio" \
        -append "console=ttyS0" \
        -nographic
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
