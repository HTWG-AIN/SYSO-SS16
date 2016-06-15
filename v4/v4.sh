#!/bin/bash

# TODO: add support for external modules using BR2_EXTERNAL
# (http://www.kaizou.org/2013/11/buildroot-custom-packages/)

# Constants
OUTPUT="stdout_1.log"
OUTPUT_ERR="errorout_1.log"

export KERNEL_VERSION="4.2.3"
export BUSYBOX_VERSION="1.24.2"
export BUILDROOT_COMMIT="1daa4c95a4bb93621292dd5c9d24285fcddb4026"

export TOOLCHAIN_PATH="/group/SYSO_WS1516/crosstool-ng/tmp/armv6j-rpi-linux-gnueabihf"
export PATH="$TOOLCHAIN_PATH/bin/:$PATH"

set -e


function usage {
    echo "Usage: $0 [--dn ][--pa ][--cp {rpi_number} ][--co ][--qe]

  --clean               delete the target directory
  --dn                  download sources
  --pa                  patch sources
  --cp                  copy generated files to TFTP folder
  --co                  compile sources
  --qe                  start qemu and a windows terminal to the serial port
  --tn                  connect to qemu via telnet
  -h, --help            show this help page, then exit
    "
}

if [ $# -lt 1 ]; then
    usage
    exit 1
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR/.."
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
export TARGET=$(pwd)
echo "* Target output directory: $TARGET"

# Make variables
export ARCH="arm"
export CROSS_COMPILE="armv6j-rpi-linux-gnueabihf-"

# U-Boot variables
export BOARD_NAME="vexpress_ca9x4"

# Buildroot variables
export PATCHES="$(echo $TARGET/files/patches/*)"
export INITRAMFS_OVERLAY_PATH="$TARGET/initramfs_overlay"
export TOOLCHAIN_PREFIX="${CROSS_COMPILE%-*}"
export KERNEL_CONFIG="$TARGET/files/configs/kernel_config"
export BUSYBOX_CONFIG="$TARGET/files/configs/busybox_config"
BUILDROOT_CONFIG="$TARGET/files/configs/buildroot_config"

function calc_usr_postfix {
    case $USER in
        niwehrle)
                    echo 01
                    ;;
        da431lop)
                    echo 02
                    ;;
        *)
                    echo 03
                    ;;
    esac
}

function clean {
    echo -n "* Cleaning up... "
    rm -rf "$TARGET"
    echo "done"
}

function download_buildroot {
    echo -n "-> Downloading buildroot... "
    cd "$TARGET"
    if [ ! -d "buildroot" ]; then
        git clone git://git.buildroot.net/buildroot > /dev/null 2>&1
        cd buildroot
        git checkout "$BUILDROOT_COMMIT" > /dev/null 2>&1
        rm -rf .git
        echo "done"
    else
        echo "already downloaded"
    fi  
}

function download_sources {
    echo "* Downloading sources..."
    # Buildroot takes care of downloading and compiling the kernel, BusyBox and U-Boot
    download_buildroot
}

function patch_sources {
    echo "* Patching sources..."
    cd "$TARGET/linux-$KERNEL_VERSION"
    patch -f -p1 < "$TARGET/files/$PATCH"
}

function compile_tftpboot_script {
    echo -n "-> Compiling tftpboot script... "
    #sed -i "s/^setenv rpi [0-9]+$/setenv rpi $1/" "$TARGET/files/tftpboot.scr.txt"
    cat "$TARGET/files/tftpboot.scr.txt" | sed -r "s/^setenv rpi.*$/setenv rpi $RPI/" > "$TARGET/files/tftpboot.scr.txt.tmp"
    mv "$TARGET/files/tftpboot.scr.txt.tmp" "$TARGET/files/tftpboot.scr.txt"
    mkimage -A arm -O linux -T script -C none -d "$TARGET/files/tftpboot.scr.txt" "$TARGET/tftpboot.scr" > /dev/null 2>&1
    echo "done"
}

function copy_to_tftp_folder {
    echo -n "-> Copying generated images to TFTP folder... "
    TFTP_FOLDER_PATH="/srv/tftp/rpi/$1"
    cat "$TARGET/buildroot/output/images/zImage" > "$TFTP_FOLDER_PATH/zImage"
    cat "$TARGET/buildroot/output/images/rootfs.cpio.uboot" > "$TFTP_FOLDER_PATH/rootfs.cpio.uboot"
    cat "$TARGET/buildroot/output/build/linux-$KERNEL_VERSION/arch/arm/boot/dts/bcm2835-rpi-b.dtb" > "$TFTP_FOLDER_PATH/bcm2835-rpi-b.dtb"
    cat "$TARGET/tftpboot.scr" > "$TFTP_FOLDER_PATH/tftpboot.scr"
    echo "done"
}

function copy_sources {
    echo "* Setting up TFTP server files for raspberry number $RPI"
    compile_tftpboot_script $RPI
    copy_to_tftp_folder $RPI
}

function compile_programs {
    echo "-> Compiling programs in $PROGRAMS_DIR..."
    cd "$TARGET/files/programs"
    for d in *; do
        if [ -d "$d" ]; then
            cd "$d"
            make
            cd ..
        fi
    done
    #echo "done"
}

function create_initramfs_overlay {
    echo "* Creating initramfs overlay directory..."
    test -d "$INITRAMFS_OVERLAY_PATH" && rm -rf "$INITRAMFS_OVERLAY_PATH"
    mkdir "$INITRAMFS_OVERLAY_PATH"
    cd "$INITRAMFS_OVERLAY_PATH"

    echo -n "-> Copying files... "
    cp -r "$TARGET"/files/rootfs/* .
    chmod +x sbin/init
    echo "done"

    test -d usr/bin || mkdir -p usr/bin
    export PROGRAMS_DIR="$(pwd)/usr/bin"
    compile_programs
}

function compile_buildroot {
    echo "-> Compiling buildroot..."
    cd "$TARGET/buildroot"
    cp "$BUILDROOT_CONFIG" .config
    make source
    make
    echo "done"
}

function compile_modules {
    export KDIR="$TARGET/buildroot/output/build/linux-$KERNEL_VERSION"
    echo "-> Compiling kernel modules..."
    cd "$TARGET/files/drivers"
    for d in *; do
        if [ -d "$d" ]; then
            echo "--> $d"
            cd "$d"
            make
            echo -n "-> Copying kernel modules to initramfs overlay directory... "
            # TODO: generated modules saved in /root for manual insertion once the kernel is booted
            test -d "$INITRAMFS_OVERLAY_PATH/root" || mkdir "$INITRAMFS_OVERLAY_PATH/root"
            cp *.ko *.sh "$INITRAMFS_OVERLAY_PATH/root"
            echo "done"
            cd ..
        fi
    done
}

function compile_sources {
    # Redirect stdout and stderr
    exec > >(tee "$OUTPUT") 2> >(tee "$OUTPUT_ERR" >&2)
    echo "* Copying rootfs overlay files..."
    create_initramfs_overlay
    echo "* Compiling sources..."
    compile_buildroot
    compile_modules
    # FIXME: workaround to generate again cpio rootfs archives with compiled modules
    compile_buildroot
}

function start_qemu {
    echo "* Starting QEMU..."
    cd "$TARGET/buildroot/output"
    KERNEL_PATH="images/zImage"
    DTB_FILE="vexpress-v2p-ca9.dtb"
    DTB_PATH="build/linux-$KERNEL_VERSION/arch/arm/boot/dts/$DTB_FILE"
    INITRAMFS_PATH="images/rootfs.cpio.uboot"
    QEMU_ARCH="arm"
    MACHINE="vexpress-a9"
    MEMORY="512"
    MACADDR="00:00:00:00:02:$(calc_usr_postfix)"
    qemu-system-$QEMU_ARCH \
        -machine "$MACHINE" \
        -kernel "$KERNEL_PATH" \
        -initrd "$INITRAMFS_PATH" \
        -dtb "$DTB_PATH" \
        -m $MEMORY \
        -net nic,macaddr="$MACADDR" \
        -net vde,sock=/tmp/vde2-tap0.ctl \
        -append "console=ttyAMA0 init=/sbin/init root=/dev/ram0" \
        -nographic
}

while [ "$1" != "" ]; do
    case $1 in
        --clean )               clean
                                ;;
        --dn )                  download_sources
                                ;;
        --pa )                  patch_sources
                                ;;
        --cp )                  shift
                                export RPI=$1
                                test -z $RPI && usage && exit 1
                                copy_sources
                                ;;
        --co )                  compile_sources
                                ;;
        --qe )                  start_qemu
                                ;;
        -h | --help )           usage
                                exit 0
                                ;;
        -i )                    create_initramfs
                                ;;
        --ck )                  compile_kernel
                                ;;
        --cbb )                 compile_busybox
                                ;;
        --cbr )                 compile_buildroot
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done
