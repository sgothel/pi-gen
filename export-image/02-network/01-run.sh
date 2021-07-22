#!/bin/bash -e

# cleanup resolv.conf
rm -f "${ROOTFS_DIR}/etc/resolv.conf"
touch "${ROOTFS_DIR}/etc/resolv.conf"
chmod 644 "${ROOTFS_DIR}/etc/resolv.conf"
