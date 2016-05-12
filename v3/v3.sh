#!/bin/bash

# Constants
OUTPUT="stdout_1.log"
OUTPUT_ERR="errorout_1.log"
export KERNEL_VERSION="4.2.3"
export BUSYBOX_VERSION="1.24.2"
export BUILDROOT_COMMIT="1daa4c95a4bb93621292dd5c9d24285fcddb4026"
export TOOLCHAIN_PATH="/group/SYSO_WS1516/crosstool-ng/tmp/armv6j-rpi-linux-gnueabihf"
export PATCH="linux-smsc95xx_allow_mac_setting.patch"
export BOARD_NAME="vexpress_ca9x4"
export DTB_FILE="vexpress-v2p-ca9.dtb"
#export DTB_FILE="bcm2835-rpi-b"
export PATH="$TOOLCHAIN_PATH/bin/:$PATH"
export ARCH="arm"
export CROSS_COMPILE="armv6j-rpi-linux-gnueabihf-"
export TOOLCHAIN_PREFIX="armv6j-rpi-linux-gnueabihf"
export INITRAMFS_OVERLAY_PATH="initramfs_overlay"

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

USR_POSTFIX=$(calc_usr_postfix)
MACADDR="00:00:00:00:02:$USR_POSTFIX"
TELNETPORT="502$USR_POSTFIX"
TELNETADDR="127.0.0.1:$TELNETPORT"

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

function create_initramfs_overlay {
    echo "* Creating initramfs..."
    cd "$TARGET"
    mkdir "$INITRAMFS_OVERLAY_PATH" 2> /dev/null
    cd "$INITRAMFS_OVERLAY_PATH"

    echo -n "-> Copying udhcpd-script... "
    mkdir etc 2> /dev/null
    cp "$TARGET/files/simple.script" etc/simple.script
    chmod 755 etc/simple.script
    echo "done"

    echo -n "-> Compiling systeminfo... "
    mkdir bin 2> /dev/null
    ${CROSS_COMPILE}gcc --static ../files/systeminfo.c -o bin/systeminfo
    echo "done"

    echo -n "-> Using provided init file... "
    mkdir sbin 2> /dev/null
    cp "$TARGET/files/init.sh" sbin/init
    chmod 755 sbin/init
    echo "done"
}

function compile_buildroot {
    echo "-> Compiling buildroot..."
    cd "$TARGET/buildroot"
    cp "$TARGET/files/buildroot_config" .config
    make source
    make
    echo "done"
}

function compile_sources {
    # Redirect stdout and stderr
    exec > >(tee "$OUTPUT") 2> >(tee "$OUTPUT_ERR" >&2)
    echo "* Copying rootfs overlay files"
    create_initramfs_overlay
    echo "* Compiling sources..."
    compile_buildroot
}

function start_qemu {
    echo "* Starting QEMU..."
    cd "$TARGET/buildroot/output"
    KERNEL_PATH="images/zImage"
    DTB_PATH="build/linux-$KERNEL_VERSION/arch/arm/boot/dts/$DTB_FILE"
    INITRAMFS_PATH="images/rootfs.cpio.uboot"
    QEMU_ARCH="arm"
    MACHINE="vexpress-a9"
    MEMORY="512"
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
export TARGET=$(pwd)
echo "* Target output directory: $TARGET"

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
