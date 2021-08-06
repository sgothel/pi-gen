#!/bin/bash -e

if [ "${USE_RASPI_SOURCE}" = "1" ]; then
    bootstrap ${RELEASE} "${ROOTFS_DIR}" http://raspbian.raspberrypi.org/raspbian/
else
    bootstrap ${RELEASE} "${ROOTFS_DIR}" http://deb.debian.org/debian/
fi
