#!/bin/bash -e

if [ "${TARGET_RASPI}" = "1" ]; then
    install -m 644 files/cmdline.txt "${ROOTFS_DIR}/boot/"
    install -m 644 files/config.txt "${ROOTFS_DIR}/boot/"
    if [ "${TARGET_ARCH}" = "armhf" ]; then
        sed -i "s/arm_64bit=1/# arm_64bit=1/g"    "${ROOTFS_DIR}/boot/config.txt"
    fi
fi
