#!/bin/bash

export POOL=tpool2
export ROOTFS_DIR="/mnt"

zpool export $POOL
zpool import -R $ROOTFS_DIR -N $POOL
