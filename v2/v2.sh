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

function calc_mac_address {
    case $USER in
        niwehrle)
                    echo 00:00:00:00:02:01
                    ;;
        da431lop)
                    echo 00:00:00:00:02:02
                    ;;
        *)
                    echo 00:00:00:00:02:03
                    ;;
    esac    
}

function clean {
    echo -n "* Cleaning up... "
    rm -rf "$TARGET"
    echo "done"
}

function download_kernel {
    echo -n "-> Downloading kernel version $KERNEL_VERSION... "
    cd "$TARGET"
    if [ ! -d "linux-$KERNEL_VERSION" ]; then
        # Download the kernel if necessary
        test -f "linux-$KERNEL_VERSION.tar.xz" || wget --quiet "https://kernel.org/pub/linux/kernel/v4.x/linux-$KERNEL_VERSION.tar.xz"
        #test -f "linux-$KERNEL_VERSION.tar.sign" || wget "https://kernel.org/pub/linux/kernel/v4.x/linux-$KERNEL_VERSION.tar.sign"
        #unxz "linux-$KERNEL_VERSION.tar.xz"
        #gpg --verify "linux-$KERNEL_VERSION.tar.sign" || \
        #   echo "Bad signature. Aborting." && \
        #   rm -rf "linux-$KERNEL_VERSION.tar" && \
        #   exit 1
        test -d "linux-$KERNEL_VERSION" && rm -rf "linux-$KERNEL_VERSION"
        echo "done"

        echo -n "-> Unpacking kernel... "
        xz -cd "linux-$KERNEL_VERSION.tar.xz" | tar xf -
        #rm "linux-$KERNEL_VERSION.tar"
        echo "done"
    else
        echo "already downloaded"
    fi
}

function download_busybox {
    echo -n "-> Downloading busybox version $BUSYBOX_VERSION... "
    cd "$TARGET"
    if [ ! -d "busybox-$BUSYBOX_VERSION" ]; then
        test -f "busybox-$BUSYBOX_VERSION.tar.bz2" || wget --quiet "http://busybox.net/downloads/busybox-$BUSYBOX_VERSION.tar.bz2"
        test -d "busybox-$BUSYBOX_VERSION" && rm -rf "busybox-$BUSYBOX_VERSION"
        echo "done"

        echo -n "-> Unpacking busybox... "
        tar xjf "busybox-$BUSYBOX_VERSION.tar.bz2"
        echo "done"
    else
        echo "already downloaded"
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

    echo -n "-> Copying and linking busybox... "
    cp -rp "$TARGET/busybox-$BUSYBOX_VERSION/_install"/* .
    echo "done"

    echo -n "-> Compiling systeminfo... "
    cd bin
    ${CROSS_COMPILE}gcc --static ../../files/systeminfo.c -o systeminfo
    cd ..
    echo "done"

    echo -n "-> Using provided init file... "
    cp "$TARGET/files/init.sh" init
    chmod 755 init
    echo "done"

    echo -n "-> Packaging initramfs files into initramfs.cpio... "
    find . | cpio --quiet -H newc -o > ../initramfs.cpio
    echo "done"

    echo -n "-> Cleaning up... "
    cd ..
    rm -rf initramfs
    echo "done"
}

function compile_kernel {
    echo "-> Compiling kernel..."
    cd "$TARGET"
    cp files/kernel_config "linux-$KERNEL_VERSION"/.config
    cd "linux-$KERNEL_VERSION"
    make -j $CORES
}

function compile_busybox {
    echo "-> Compiling busybox..."
    cd "$TARGET"
    cp files/busybox_config "busybox-$BUSYBOX_VERSION"/.config
    cd "busybox-$BUSYBOX_VERSION"
    make -j $CORES
    make -j $CORES install
}

function compile_sources {
    echo "* Compiling sources..."
    compile_kernel
    compile_busybox
    create_initramfs
}

function start_qemu {
    echo "* Starting QEMU..."
    cd "$TARGET"
    QEMU_ARCH="arm"
    # TODO: versatileab?
    MACHINE="vexpress-a9"
    qemu-system-$QEMU_ARCH \
        -machine "$MACHINE" \
        -net nic,vlan=0,macaddr=$(calc_mac_address) \
        -kernel "linux-$KERNEL_VERSION/arch/$ARCH/boot/zImage" \
        -initrd "initramfs.cpio" \
        -append "console=ttyS0" \
        -nographic
}

function usage {
    echo "Usage: $0 [--dn ][--pa ][--cp ][--co ][--qe]
 
  --clean               delete the target directory
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
    echo -n "* Creating target folder... "
    mkdir target
    echo "done"
    echo -n "* Copying files... "
    cp -r "$DIR/files" target/
    echo "done"
else
    echo -n "* Copying files... "
    rm -rf target/files
    cp -r "$DIR/files" target/
    echo "done"
fi
cd target
TARGET=$(pwd)
echo "* Target output directory: $TARGET"

while [ "$1" != "" ]; do
    case $1 in
        --clean )               clean
                                ;;
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
