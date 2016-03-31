#!/bin/bash

function create_initramfs {
	mkdir initramfs
	mv "$1" initramfs
	cd initramfs
	mkdir -p dev sbin bin usr/bin etc var tmp
	mv "$1" bin/busybox
	ln -s /bin/busybox bin/sh

	# Simple init file to launch busybox
	cat > init << EOF
#!/bin/sh
#mount -t proc none /proc
#mount -t sysfs none /sys
exec /bin/sh
EOF

	chmod +x init
	find . | cpio -H newc -o > ../initramfs.cpio
	cd ..
	rm -rf initramfs
}

if [ $# -ne 2 ]; then
	echo "Usage: $0 <kernel_config> <busybox_binary>"
	exit 0
fi

OUTPUT="stdout_1.log"
OUTPUT_ERR="errorout_1.log"
VERSION="4.2.3"
KERNEL_CONFIG="$1"
BUSYBOX="$2"
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
	#	echo "Bad signature. Aborting." && \
	#	rm -rf "linux-$VERSION.tar" && \
	#	exit 1
	test -d "linux-$VERSION" && rm -rf "linux-$VERSION"
	xz -cd "linux-$VERSION.tar.xz" | tar xvf "linux-$VERSION.tar" -
	#rm "linux-$VERSION.tar"
fi
cp "$KERNEL_CONFIG" "linux-$VERSION"/.config
cp "$BUSYBOX" "linux-$VERSION"/busybox
cd "linux-$VERSION"

# Create initramfs file
create_initramfs busybox

# Compile
make -j $CORES
cd ..
