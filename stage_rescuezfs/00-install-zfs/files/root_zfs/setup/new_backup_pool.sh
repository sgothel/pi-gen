#!/bin/bash

backupname=backupdisk1

DISK1=ata-QEMU_HARDDISK_QM00007

export POOL=${backupname}
export ZFS_COMPRESSION_METHOD=lz4
# export ZFS_COMPRESSION_METHOD=zstd

zpool create -f -o ashift=12 -o autoexpand=on \
      -O atime=off -O compression=off \
      -O mountpoint=/mnt/${backupname} \
      -d \
        -o feature@allocation_classes=enabled \
        -o feature@async_destroy=enabled \
        -o feature@block_cloning=enabled \
        -o feature@bookmarks=enabled \
        -o feature@device_rebuild=enabled \
        -o feature@embedded_data=enabled \
        -o feature@empty_bpobj=enabled \
        -o feature@enabled_txg=enabled \
        -o feature@extensible_dataset=enabled \
        -o feature@filesystem_limits=enabled \
        -o feature@hole_birth=enabled \
        -o feature@large_blocks=enabled \
        -o feature@livelist=enabled \
        -o feature@log_spacemap=enabled \
        -o feature@lz4_compress=enabled \
        -o feature@project_quota=enabled \
        -o feature@resilver_defer=enabled \
        -o feature@spacemap_histogram=enabled \
        -o feature@spacemap_v2=enabled \
        -o feature@userobj_accounting=enabled \
        -o feature@zilsaxattr=enabled \
        -o feature@zpool_checkpoint=enabled \
        \
        -o feature@encryption=enabled \
      \
      $POOL \
      /dev/disk/by-id/$DISK1-part3 

zpool autoexpand=on $POOL
zpool autoreplace=off $POOL
zpool listsnapshots=off $POOL

zfs set mountpoint=/mnt/${backupname} $POOL
zfs set dedup=off $POOL
zfs set compression=off $POOL
zfs set atime=off $POOL
zfs set mountpoint=none $POOL
zfs set aclinherit=passthrough $POOL
zfs set acltype=posixacl $POOL
zfs set xattr=sa $POOL

# Create Datasets ..
zfs create -o encryption=on -o keyformat=passphrase $POOL/backup-host

