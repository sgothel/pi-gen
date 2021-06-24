#!/bin/sh -e

# disabled for now
# tar -zxvf files/zafena.tar.gz -C "${ROOTFS_DIR}/"

cp -av files/*            "${ROOTFS_DIR}/"
cp -av files.elevator/*   "${ROOTFS_DIR}/"
cp -av files.zafena_app/* "${ROOTFS_DIR}/"
