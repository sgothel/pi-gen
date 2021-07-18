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

minimum() {
    if [ $1 -lt $2 ]; then
        echo -n $1
    else
        echo -n $2
    fi
}

if [ -z "${1}" -o -z "${2}" ]; then
    echo "Usage: $0 <grub-image-file> <block-device (not partition)>"
    exit 2
fi

readonly SIZE_MBR=512
readonly SIZE_IMG1=446
# 1MiB min MBR gap recommended
readonly let MIN_IMG2_SIZE=$((1024 * 1024))

IMG_FILE="${1}"
BLK_DEV="${2}"

PARTED_OUT=`parted -s -m "${BLK_DEV}" unit B print`
PART_NO=1
PART_START=`echo "${PARTED_OUT}" | grep "^${PART_NO}:" | awk -F: ' { print substr($2,1,length($2)-1) } '`
let SIZE_DEV=${PART_START}

SIZE_IMG_FILE=`du -b ${IMG_FILE} | awk ' { print $1 }'`

SIZE_IMG_MAX=$(minimum ${SIZE_DEV} ${SIZE_IMG_FILE})

echo "Using size ${SIZE_IMG_MAX}, having image size ${SIZE_IMG_FILE} and device size ${SIZE_DEV} all in bytes."

let SIZE_IMG2=${SIZE_IMG_MAX}-${SIZE_MBR}
if [ ${SIZE_IMG2} -lt ${MIN_IMG2_SIZE} ]; then
    echo "Available MBR gap for image2 ${SIZE_IMG2} < recommended ${MIN_IMG2_SIZE}, abort."
    exit 2
fi

echo "Storing first 446 bytes from ${IMG_FILE} to start of ${BLK_DEV}."
dd if=${IMG_FILE} of=${BLK_DEV} bs=4M count=${SIZE_IMG1} conv=notrunc iflag=count_bytes,skip_bytes oflag=seek_bytes,dsync

echo "Storing ${SIZE_IMG2} bytes from ${IMG_FILE} starting at ${SIZE_MBR} to ${BLK_DEV} starting at ${SIZE_MBR}."
dd if=${IMG_FILE} of=${BLK_DEV} bs=4M count=${SIZE_IMG2} skip=${SIZE_MBR} seek=${SIZE_MBR} conv=notrunc iflag=count_bytes,skip_bytes oflag=seek_bytes,dsync
sync

