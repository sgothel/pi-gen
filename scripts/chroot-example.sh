#!/bin/bash -e

# 
# Example script mounting a qcow-image
# and performing somce actions on-top of it.
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

IMAGE=$1
export ROOTFS_DIR=$2

echo "${SCRIPT_DIR}/../imagetool.sh" -m "${IMAGE}" "${ROOTFS_DIR}"
"${SCRIPT_DIR}/../imagetool.sh" -m "${IMAGE}" "${ROOTFS_DIR}"

source "${SCRIPT_DIR}/common"

on_chroot << EOF
    # do something ...
    apt-get -o APT::Acquire::Retries=3 install -y nasm yasm
EOF

echo "${SCRIPT_DIR}/../imagetool.sh" -u "${ROOTFS_DIR}"
"${SCRIPT_DIR}/../imagetool.sh" -u "${ROOTFS_DIR}"
