#!/bin/bash

# 
# Creates a new raw image file:
# - creating one vfat partition covering whole size
# - formating partition with vfat
# - provision GRUB boot-code (expecting 'grub' folder on vfat partition)
# - copy custom files to vfat partition
#
sdir=`dirname $(readlink -f "${BASH_SOURCE[0]}")`
rootdir=`dirname $sdir`

usage() {
    echo "Usage: $0 <image-file> <total-size> <mount-point> <provisioning-dir>"
    echo "For <total-size> use G for GiB or M for MiB denominator"
}

if [ -z "${1}" -o -z "${2}" -o -z "${3}" -o -z "${4}" ]; then
    usage
    exit 2
fi

readonly grub_image="data/grub-i386-image01.bin"
# codepage is hardcoded in 'loop_rootfs' and scripts, as well as required by pi-gen build
readonly FAT_CODEPAGE="437"

IMG_FILE="${1}"
IMG_FILE_SIZE="${2}"
MNT_DIR="${3}"
SRC_DIR="${4}"

rm -f ${IMG_FILE}
dd if=/dev/zero of=${IMG_FILE} bs=4M count=${IMG_FILE_SIZE} conv=notrunc iflag=count_bytes,skip_bytes oflag=seek_bytes,dsync status=progress

sfdisk ${IMG_FILE} << EOF
4MiB,,c,*;
EOF
sync

nbd_dev=$(${rootdir}/imagetool.sh --connect-raw ${IMG_FILE})
if [ -z "${nbd_dev}" ]; then
    echo "No mapped nbd to image, NBD_DEV '${nbd_dev}', abort"
    exit 2
fi

p1dev="/dev/mapper/${nbd_dev}p1"
mkfs.fat -n BOOT -F 32 --codepage=${FAT_CODEPAGE} -v ${p1dev}
sync

${sdir}/grubimg_to_blockdevice.sh "${grub_image}" "/dev/${nbd_dev}"

mount ${p1dev} ${MNT_DIR}
cp -dR --preserve=mode,timestamps ${SRC_DIR}/* ${MNT_DIR}/
sync
umount ${MNT_DIR}
sync

# just make sure ..
fsck.vfat -V -y ${p1dev}
fsck.vfat -V -y ${p1dev}

${rootdir}/imagetool.sh --disconnect ${nbd_dev}

echo "New image ${IMG_FILE} partitioned, formatted and provisioned with GRUB boot-code and custom files."

