#!/bin/bash

# Constants
OUTPUT="stdout_1.log"
OUTPUT_ERR="errorout_1.log"
KERNEL_VERSION="4.2.3"
BUSYBOX_VERSION="1.24.2"
CORES=$(cat /proc/cpuinfo | grep processor | wc -l)
TOOLCHAIN_PATH="/group/SYSO_WS1516/crosstool-ng/tmp/armv6j-rpi-linux-gnueabihf/bin/"
PATCH="linux-smsc95xx_allow_mac_setting.patch"

# Environment variables
export PATH="$TOOLCHAIN_PATH:$PATH"
export ARCH="arm"
export CROSS_COMPILE="armv6j-rpi-linux-gnueabihf-"
export CC="ccache gcc"

# arch needs to be set before accesing it
KERNEL_PATH="linux-$KERNEL_VERSION/arch/$ARCH/boot/"

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

function download_buildroot {
    echo -n "-> Downloading buildroot... "
    cd "$TARGET"
    if [ ! -d "buildroot" ]; then
        git clone git://git.buildroot.net/buildroot
        git checkout 1daa4c95a4bb93621292dd5c9d24285fcddb4026
        rm -rf .git*
        echo "done"
    else
        echo "already downloaded"
    fi  
}
function download_sources {
    echo "* Downloading sources..."
    download_kernel
    download_busybox
    download_buildroot
}

function patch_sources {
    echo "* Patching sources..."
    cd "$TARGET/$KERNEL_PATH"
    patch -f -p1 < "$Target/files/$PATCH"
}

function copy_sources {
    echo "* Copying GitLab sources..."
    echo "* unused"
}

function create_initramfs {
    echo "* Creating initramfs..."
    cd "$TARGET"
    mkdir initramfs
    cd initramfs
    
    echo -n "-> Copying udhcpd-script... "
    mkdir etc
    cd etc
    cp "$TARGET/files/simple.script" simple.script
    chmod 755 simple.script
    cd ..
    echo "done"
    
    echo -n "-> Copying and linking busybox... "
    cp -rp "$TARGET/busybox-$BUSYBOX_VERSION/_install"/* .
    echo "done"

    echo -n "-> Compiling systeminfo... "
    cd bin
    ${CROSS_COMPILE}gcc --static ../../files/systeminfo.c -o systeminfo
    cd ..
    echo "done"

    echo -n "-> Adding root user..."
    echo "root::0:0:root:/root:/bin/sh" > etc/passwd && chmod 655 etc/passwd
    echo "root:x:0:" > etc/group && chmod 655 etc/group
    # Password: toor
    #echo 'root:$1$hMn2tdnr$yYjf4Dobq.yhgpC2wcFFs1:::::::' > etc/shadow && chmod 600 etc/shadow
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
    # Redirect stdout and stderr
    exec > >(tee "$OUTPUT") 2> >(tee "$OUTPUT_ERR" >&2)
    echo "* Compiling sources..."
    compile_kernel
    compile_busybox
    create_initramfs
}

function start_qemu {
    echo "* Starting QEMU..."
    cd "$TARGET"
    QEMU_ARCH="arm"
    MACHINE="vexpress-a9"
    qemu-system-$QEMU_ARCH \
        -machine "$MACHINE" \
        -kernel $KERNEL_PATH"zImage" \
        -dtb $KERNEL_PATH"dts/vexpress-v2p-ca9.dtb" \
        -initrd "initramfs.cpio" \
        -net nic,macaddr="$MACADDR" \
        -net vde,sock=/tmp/vde2-tap0.ctl \
        -append "console=ttyAMA0" \
        -nographic
}

function usage {
    echo "Usage: $0 [--dn ][--pa ][--cp ][--co ][--qe]
 
  --clean               delete the target directory
  --dn                  download sources
  --pa                  patch sources
  --cp                  copy GitLab sources -> TODO
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
                                exit 0
                                ;;
        -i )                    create_initramfs
                                ;;
        --ck )                  compile_kernel
                                ;;
        --cb )                  compile_busybox
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done
