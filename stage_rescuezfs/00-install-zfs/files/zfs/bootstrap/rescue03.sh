#!/bin/bash

export BASE_DIR=`dirname $(readlink -f "${BASH_SOURCE[0]}")`

source "${BASE_DIR}/rescue.cfg"

cat /proc/mounts | awk '{print $2}' | grep "${ROOTFS_DIR}" | sort -r | xargs umount
