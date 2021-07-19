#!/bin/bash

export BASE_DIR=`dirname $(readlink -f "${BASH_SOURCE[0]}")`

source "${BASE_DIR}/rescue00.sh"

zpool import -f -R ${ROOTFS_DIR} ${POOL}
