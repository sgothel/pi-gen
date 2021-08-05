#!/bin/bash -e

if [ "${TARGET_RASPI}" = "1" -a "${TARGET_ARCH}" = "armhf" ]; then
    bootstrap ${RELEASE} "${ROOTFS_DIR}" http://raspbian.raspberrypi.org/raspbian/
else
    bootstrap ${RELEASE} "${ROOTFS_DIR}" http://deb.debian.org/debian/
fi
