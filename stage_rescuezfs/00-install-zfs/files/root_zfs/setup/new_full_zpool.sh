#!/bin/bash

DISK1=ata-QEMU_HARDDISK_QM00007
DISK2=ata-QEMU_HARDDISK_QM00009
DISK3=ata-QEMU_HARDDISK_QM00011

export ROOTFS_DIR="/mnt"
# export MYSWAPSIZE=64G
# export MYSWAPSIZE=1G

export POOL=tpool2
export ZFS_COMPRESSION_METHOD=lz4
# export ZFS_COMPRESSION_METHOD=zstd

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
      $POOL raidz1 \
      /dev/disk/by-id/$DISK1-part3 \
      /dev/disk/by-id/$DISK2-part3 \
      /dev/disk/by-id/$DISK3-part3

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

if [ ! -z "$MYSWAPSIZE" ]; then
    # SWAP
    zfs create -V $MYSWAPSIZE -b $(getconf PAGESIZE) -o compression=zle \
          -o logbias=throughput -o sync=always \
          -o primarycache=metadata -o secondarycache=none \
          -o com.sun:auto-snapshot=false $POOL/swap

    zfs set compression=zle $POOL/swap
    zfs set logbias=throughput $POOL/swap
    zfs set sync=always $POOL/swap
    zfs set primarycache=metadata $POOL/swap
    zfs set secondarycache=none $POOL/swap
    zfs set com.sun:auto-snapshot=false $POOL/swap
    zfs set checksum=off $POOL/swap

    mkswap -f /dev/zvol/$POOL/swap
    echo /dev/zvol/$POOL/swap none swap defaults 0 0 >> /etc/fstab
    # UUID=ee57ce05-7287-4b37-93c4-03aeaba756f1
    # /etc/fstab
    # /dev/zvol/$POOL/swap   none  		   swap    defaults  0  0
    # 
    # swapon /dev/zvol/$POOL/swap
    #
    echo "Swap: /etc/fstab modified"
    echo "Swap: Enable: swapon /dev/zvol/$POOL/swap"
fi

