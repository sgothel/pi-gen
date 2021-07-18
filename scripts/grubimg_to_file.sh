#!/bin/bash

#
# GRUB Images
# ============
# Images (stages) holding the boot-code are stored in the following spaces:
#
# * [  0 -   445] 446 bytes 1st image within MBR
# * [446 -   511]  66 bytes partition table and signature (2 bytes)
# * [512 - xxxxx] ~64 kB    2nd image(s+) between MBR and first partition (MBR gap)
#
# MBR Total Size
# ================
#
# * 446 + 64 + 2 = 512
#
# using
#
# * 446 bytes – boot code
# * 64 bytes – partition table
# * 2 bytes – signature (??)
#
 
if [ -z "${1}" -o -z "${2}" ]; then
    echo "Usage: $0 <block-device (not partition)> <grub-image-file>"
    exit 2
fi

readonly let SIZE_MBR=512
readonly let SIZE_IMG1=446
# 1MiB min MBR gap recommended
readonly let MIN_IMG2_SIZE=$((1024 * 1024))

BLK_DEV="${1}"
IMG_FILE="${2}"

PARTED_OUT=`parted -s -m "${BLK_DEV}" unit B print`
PART_NO=1
PART_START=`echo "${PARTED_OUT}" | grep "^${PART_NO}:" | awk -F: ' { print substr($2,1,length($2)-1) } '`
let SIZE_IMG_MAX=${PART_START}

let SIZE_IMG2=${SIZE_IMG_MAX}-${SIZE_MBR}
if [ ${SIZE_IMG2} -lt ${MIN_IMG2_SIZE} ]; then
    echo "Available MBR gap for image2 ${SIZE_IMG2} < recommended ${MIN_IMG2_SIZE}, abort."
    exit 2
fi

echo "Storing ${SIZE_IMG_MAX} bytes from start of ${BLK_DEV} to ${IMG_FILE}."
dd if=${BLK_DEV} of=${IMG_FILE} bs=4M count=${SIZE_IMG_MAX} conv=notrunc iflag=count_bytes,skip_bytes oflag=seek_bytes,dsync
sync
