#!/bin/bash

export CURRENT_IMAGE
export CURRENT_MOUNTPOINT

# 1 boot, 2 data, 3 root
export NBD_DEV
export MAP_BOOT_DEV
export MAP_DATA_DEV
export MAP_ROOT_DEV

# disconnect image from block device
disconnect_blkdev() {
	kpartx -d $1
	qemu-nbd -d $1
	NBD_DEV=
	MAP_BOOT_DEV=
	MAP_DATA_DEV=
	MAP_ROOT_DEV=
	CURRENT_IMAGE=
}
export -f disconnect_blkdev

disconnect_blkdev $1
