#! /bin/bash -e

#
# Setup ZFS pool
#

export BASE_DIR=`dirname $(readlink -f "${BASH_SOURCE[0]}")`

source "${BASE_DIR}/install.cfg"

source "${BASE_DIR}/common.sh"

export ZFS_COMPRESSION_METHOD=${ZFS_COMPRESSION_METHOD:-lz4}

modprobe zfs

# If you are re-using a MDADM disk, clear it as necessary:
# 
# If the disk was previously used in an MD array, zero the superblock:
#apt install --yes mdadm
#mdadm --zero-superblock --force /dev/disk/by-id/$DISK1
#mdadm --zero-superblock --force /dev/disk/by-id/$DISK2
#mdadm --zero-superblock --force /dev/disk/by-id/$DISK3
 
# Clear the partition table:
sgdisk --zap-all /dev/disk/by-id/$DISK1
sgdisk --zap-all /dev/disk/by-id/$DISK2
sgdisk --zap-all /dev/disk/by-id/$DISK3
sync

# 2.2 Partition your disk:
#
# We assume advanced format: 4096 bytes per sector, 8 multiple
#
# Legacy (BIOS) booting (part-1): Used for GRUB boot-code in 'MBR-gap':
sgdisk -a1 -n1:40:8191 -t1:EF02 /dev/disk/by-id/$DISK1
sgdisk -a1 -n1:40:8191 -t1:EF02 /dev/disk/by-id/$DISK2
sgdisk -a1 -n1:40:8191 -t1:EF02 /dev/disk/by-id/$DISK3
sync

# ZFS partition: Remainder
sgdisk -n2:0:0     -t2:BF01 /dev/disk/by-id/$DISK1
sgdisk -n2:0:0     -t2:BF01 /dev/disk/by-id/$DISK2
sgdisk -n2:0:0     -t2:BF01 /dev/disk/by-id/$DISK3
sync

sleep 3
sync

##
## Create POOL
##

mkdir -p ${ROOTFS_DIR}

#
# Manually enabled ZFS features for GRUB compatibility!
# See https://wiki.archlinux.org/title/ZFS#GRUB-compatible_pool_creation
# Tested w/ Grub 2.04-19
#
zpool create -f -o ashift=12 -o autoexpand=on \
      -O atime=off -O compression=off \
      -O mountpoint=/ -R ${ROOTFS_DIR} \
      -d \
        -o compatibility=grub2_readonly \
        -o feature@async_destroy=enabled \
        -o feature@bookmarks=enabled \
        -o feature@embedded_data=enabled \
        -o feature@empty_bpobj=enabled \
        -o feature@enabled_txg=enabled \
        -o feature@extensible_dataset=enabled \
        -o feature@filesystem_limits=enabled \
        -o feature@hole_birth=enabled \
        -o feature@large_blocks=enabled \
        -o feature@lz4_compress=enabled \
        -o feature@spacemap_histogram=enabled \
        -o feature@allocation_classes=enabled \
        -o feature@device_rebuild=enabled \
        -o feature@livelist=enabled \
        -o feature@log_spacemap=enabled \
        -o feature@obsolete_counts=enabled \
        -o feature@project_quota=enabled \
        -o feature@resilver_defer=enabled \
        -o feature@spacemap_v2=enabled \
        -o feature@userobj_accounting=enabled \
        -o feature@zpool_checkpoint=enabled \
      \
      $POOL raidz2 \
      /dev/disk/by-id/$DISK1-part2 \
      /dev/disk/by-id/$DISK2-part2 \
      /dev/disk/by-id/$DISK3-part2

zpool autoexpand=on $POOL
zpool autoreplace=off $POOL
zpool listsnapshots=off $POOL

zfs set dedup=off $POOL
zfs set compression=off $POOL
zfs set atime=off $POOL
zfs set mountpoint=none $POOL
zfs set aclinherit=passthrough $POOL
zfs set acltype=posixacl $POOL
zfs set xattr=sa $POOL

# Create Dataset System Root 
zfs create -o mountpoint=none $POOL/system
zfs create -o mountpoint=/ $POOL/system/debian
#zfs mount $POOL/system/debian
zpool set bootfs=$POOL/system/debian $POOL

zfs create -o compression=${ZFS_COMPRESSION_METHOD} $POOL/system/debian/var

# Create Datasets ..
zfs create -o mountpoint=/home $POOL/users
zfs create -o mountpoint=/root $POOL/users/root

zfs create -o mountpoint=/backup -o compression=${ZFS_COMPRESSION_METHOD} $POOL/backup
zfs create -o mountpoint=/data $POOL/data
zfs create -o mountpoint=/srv $POOL/services
zfs create -o mountpoint=/usr/local/projects -o compression=${ZFS_COMPRESSION_METHOD} $POOL/projects

## Export / Import ( '-d ..' also changes the dev names )
##zpool export $POOL
##zpool import -d /dev/disk/by-id -R ${ROOTFS_DIR} $POOL

