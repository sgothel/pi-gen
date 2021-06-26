#!/bin/bash

export CURRENT_IMAGE
export CURRENT_MOUNTPOINT

# 1 boot, 2 data, 3 root
export NBD_DEV
export MAP_BOOT_DEV
export MAP_DATA_DEV
export MAP_ROOT_DEV

# find and initialize free block device nodes
init_nbd() {
	modprobe nbd max_part=16
	if [ -z "${NBD_DEV}" ]; then
	for x in /sys/class/block/nbd* ; do
		S=`cat $x/size`
		if [ "$S" == "0" ] ; then
			NBD_DEV=/dev/$(basename $x)
			MAP_BOOT_DEV=/dev/mapper/$(basename $x)p1
			MAP_DATA_DEV=/dev/mapper/$(basename $x)p2
			MAP_ROOT_DEV=/dev/mapper/$(basename $x)p3
            echo Use NBD Device $NBDDEV
            echo Use MAP_BOOT_DEV $MAP_BOOT_DEV
            echo Use MAP_DATA_DEV $MAP_DATA_DEV
            echo Use MAP_ROOT_DEV $MAP_ROOT_DEV
			break
		fi
	done
	fi
}
export -f init_nbd

# connect image to block device
connect_blkdev() {
	init_nbd
	qemu-nbd --discard=unmap -c $NBD_DEV "$1"
	sync
	kpartx -a $NBD_DEV
	sync
	CURRENT_IMAGE="$1"
}
export -f connect_blkdev

connect_blkdev $1
