#!/bin/bash

function create_initramfs {
    mkdir initramfs
    cd initramfs
    mkdir -p dev sbin bin usr/bin etc var tmp
    cd bin
    cp "$1" busybox
    chmod 755 busybox
    for bin in mount echo ls cat ps dmesg sysctl sh sleep; do
        ln -s busybox $bin
    done
    cd ..

    if [ -z "$2" ]; then
        # Simple init file to launch busybox
        echo "* No init file provided. Configuring initramfs to launch Busybox shell."
        echo '#!/bin/sh' > init
        echo 'exec /bin/sh' >> init
    else
        echo "* Using provided init file '$2'"
        cp "$2" init
    fi
    chmod 755 init

    find . | cpio -H newc -o > ../initramfs.cpio
    cd ..
    rm -rf initramfs
}

if [ $# -lt 2 ]; then
    echo "Usage: $0 <kernel_config> <busybox_binary> [init_file]"
    exit 0
fi

OUTPUT="stdout_1.log"
OUTPUT_ERR="errorout_1.log"
VERSION="4.2.3"
KERNEL_CONFIG="$(readlink -f $1)"
BUSYBOX="$(readlink -f $2)"
INIT="$(readlink -f $3 2> /dev/null)"
CORES=$(cat /proc/cpuinfo | grep processor | wc -l)
export ARCH="x86"
export CC="ccache gcc"

# Redirect stdout and stderr
#exec > $OUTPUT 2> $OUTPUT_ERR

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
    xz -cd "linux-$VERSION.tar.xz" | tar xvf "linux-$VERSION.tar" -
    #rm "linux-$VERSION.tar"
fi
cp "$KERNEL_CONFIG" "linux-$VERSION"/.config
cd "linux-$VERSION"

# Create initramfs file
create_initramfs "$BUSYBOX" "$INIT"

# Compile
make -j $CORES
cd ..
