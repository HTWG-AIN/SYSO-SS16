#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd $DIR/..
echo "$PWD"
if [ ! -d "target" ]; then
    echo "create target folder"
    mkdir target
fi
cd target
TARGET=$(pwd)
echo "target: $TARGET"
OUTPUT="stdout_1.log"
OUTPUT_ERR="errorout_1.log"
VERSION="4.2.3"
CORES=$(cat /proc/cpuinfo | grep processor | wc -l)
export ARCH="x86"
export CC="ccache gcc"


function clean {
    echo "clean"
    cd $TARGET/..
    rm -r target/
    mkdir target
}

function copy_files {
    echo "copy files"
    cd $TARGET
    if [ -e "files" ]; then
        echo "deleting files"
        rm -r files
    fi
    cp -r $DIR/files ./files
}

function create_initramfs {
    echo "create initramfs"
    cd $TARGET
    mkdir initramfs
    cd initramfs
    mkdir -p dev sbin bin usr/bin etc var tmp
    cd bin
    #currently in target/initramfs/bin
    gcc --static -m32 ../../files/systeminfo.c -o systeminfo
    cp $TARGET/busybox busybox
    chmod 755 busybox
    for bin in mount echo ls cat ps dmesg sysctl sh sleep; do
        ln -s busybox $bin
    done
    cd ..

    echo "* Using provided init file"
    cp $TARGET/files/init.sh init

    chmod 755 init

    find . | cpio -H newc -o > ../initramfs.cpio
    cd ..
    rm -rf initramfs
}

function usage {
    echo "Usage: $0 TODO"
    exit 0
}

function start_qemu {
    echo "start qemu"
    cd $TARGET
    ARCH="i386"
    qemu-system-$ARCH -kernel "linux-$VERSION/arch/x86/boot/bzImage" -initrd "initramfs.cpio" -curses
}


function download_busybox {
    echo "download busybox"
    cd $TARGET
    if [ ! -e "busybox" ]; then
        git archive --remote=git@burns.in.htwg-konstanz.de:labworks-SYSO_SS16/syso_ss16_skeleton.git HEAD:V1 busybox | tar -x
    fi
}


function download_kernel {
    echo "download kernel"
    cd $TARGET
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

function compile_kernel {
    echo "compile kernel"
    cd $TARGET
    cp files/kernel_config "linux-$VERSION"/.config
    cd "linux-$VERSION"

    # Compile
    make -j $CORES
}



# Redirect stdout and stderr
#exec > $OUTPUT 2> $OUTPUT_ERR

function do_all {
    copy_files
    download_kernel
    download_busybox
    compile_kernel
    # Create initramfs file
    create_initramfs
    start_qemu
}

if [ $# -lt 1 ]; then
    usage
fi

while [ "$1" != "" ]; do
    case $1 in
        -c | --copy )           copy_files
                                ;;
        -a | --all )            do_all
                                ;;
        --initramfs )           create_initramfs
                                ;;
        -q | --qemu )           start_qemu
                                ;;
        -h | --help )           usage
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done
