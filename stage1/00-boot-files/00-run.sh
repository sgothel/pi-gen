#!/bin/bash -e

if [ "${TARGET_RASPI}" = "1" ]; then
    install -m 644 files/cmdline.txt "${ROOTFS_DIR}/boot/"
    install -m 644 files/config.txt "${ROOTFS_DIR}/boot/"
fi
