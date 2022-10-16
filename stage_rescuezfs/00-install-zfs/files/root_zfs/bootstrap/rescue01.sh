#!/bin/bash

export BASE_DIR=`dirname $(readlink -f "${BASH_SOURCE[0]}")`

source "${BASE_DIR}/rescue.cfg"

zpool import -f -R ${ROOTFS_DIR} ${POOL}
