#!/bin/bash

# Constants
OUTPUT="stdout_1.log"
OUTPUT_ERR="errorout_1.log"
VERSION="4.2.3"
CORES=$(cat /proc/cpuinfo | grep processor | wc -l)
export ARCH="x86"
export CC="ccache gcc"

function copy_files {
    echo "* Copying files..."
    cd "$TARGET"
    if [ -e "files" ]; then
        echo "* Deleting files..."
        rm -r files
    fi
    cp -r "$DIR/files" ./files
}

function download_busybox {
    echo "* Downloading Busybox..."
    cd "$TARGET"
    if [ ! -e "busybox" ]; then
        git archive --remote=git@burns.in.htwg-konstanz.de:labworks-SYSO_SS16/syso_ss16_skeleton.git HEAD:V1 busybox | tar -x
    fi
}

function download_kernel {
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

function compile_kernel {
    echo "* Compiling kernel..."
    cd "$TARGET"
    cp files/kernel_config "linux-$VERSION"/.config
    cd "linux-$VERSION"

    # Compile
    make -j $CORES
}

function create_initramfs {
    echo "* Creating initramfs..."
    cd "$TARGET"
    mkdir initramfs
    cd initramfs
    mkdir -p dev sbin bin usr/bin etc var tmp
    cd bin
    #currently in target/initramfs/bin
    gcc --static -m32 ../../files/systeminfo.c -o systeminfo
    cp "$TARGET/busybox" busybox
    chmod 755 busybox
    for bin in mount echo ls cat ps dmesg sysctl sh sleep; do
        ln -s busybox $bin
    done
    cd ..

    echo "* Using provided init file..."
    cp "$TARGET/files/init.sh" init

    chmod 755 init

    find . | cpio -H newc -o > ../initramfs.cpio
    cd ..
    rm -rf initramfs
}

function start_qemu {
    # TODO: replace curses with serial tty: http://nairobi-embedded.org/qemu_serial_terminal_redirection.html
    echo "* Starting qemu..."
    cd "$TARGET"
    ARCH="i386"
    qemu-system-$ARCH -kernel "linux-$VERSION/arch/x86/boot/bzImage" -initrd "initramfs.cpio" -curses
}

function clean {
    echo "* Cleaning up..."
    cd "$TARGET/.."
    rm -r target/
    mkdir target
}

function usage {
    echo "Usage: $0 [OPTION]... 
 
  -a, --all             do all without cleaning.
  -b, --batch           run all the tasks uninteractively (stdout and stderr teed to files and QEMU won't be executed).
  -q, --qemu            start qemu.
  -h, --help            show this help page, then exit.
  --clean               clean up the target directory.
  --copy_files          copy resource files.
  --initramfs           create the initramfs using the resources.
  --download_busybox    downloads the busybox from the skeleton git repository.
  --compile_kernel      compiles the kernel.
    "
    
    exit 0
}

function do_all {
    copy_files
    download_kernel
    download_busybox
    compile_kernel
    # Create initramfs file
    create_initramfs
    start_qemu
}

function do_all_batch {
    # Redirect stdout and stderr
    exec > >(tee "$OUTPUT") 2> >(tee "$OUTPUT_ERR" >&2)
    copy_files
    download_kernel
    download_busybox
    compile_kernel
    # Create initramfs file
    create_initramfs
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
        -a | --all )            do_all
                                ;;
        -b | --batch )          do_all_batch
                                ;;
        -q | --qemu )           start_qemu
                                ;;
        -h | --help )           usage
                                ;;
        --clean )               clean
                                ;;
        --copy_files )          copy_files
                                ;;
        --initramfs )           create_initramfs
                                ;;
        --download_busybox )    download_busybox
                                ;;
        --compile_kernel )      compile_kernel
                                ;;        
        * )                     usage
                                exit 1
    esac
    shift
done
