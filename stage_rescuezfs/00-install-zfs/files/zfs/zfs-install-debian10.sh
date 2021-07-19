#! /bin/sh

ZFSDEBDIR=`readlink -f ./zfs-linux-2.0.5-1-debian10-amd64`

#skipped:
# libzfs4-devel_2.0.5-1_amd64.deb
# python3-pyzfs_2.0.5-1_amd64.deb
# zfs-dracut_2.0.5-1_amd64.deb
# zfs-test_2.0.5-1_amd64.deb
# zfs-2.0.5.tar.gz

#apt-get install libnvpair1 libuutil1 libzpool2 libzfs2
dpkg -i $ZFSDEBDIR/libuutil3_2.0.5-1_amd64.deb
dpkg -i $ZFSDEBDIR/libnvpair3_2.0.5-1_amd64.deb
dpkg -i $ZFSDEBDIR/libzfs4_2.0.5-1_amd64.deb
dpkg -i $ZFSDEBDIR/libzpool4_2.0.5-1_amd64.deb
#apt-get install zfs-dkms zfs zfs-initramfs
dpkg -i $ZFSDEBDIR/zfs-dkms_2.0.5-1_amd64.deb
dpkg -i $ZFSDEBDIR/zfs_2.0.5-1_amd64.deb
dpkg -i $ZFSDEBDIR/zfs-initramfs_2.0.5-1_amd64.deb

apt-mark manual zfs-initramfs zfs zfs-dkms libzfs2 libzfs4 libzpool2 libzpool4 libuutil1 libuutil3 libnvpair1 libnvpair3

# FIX /etc/default/zfs
# ZFS_INITRD_ADDITIONAL_DATASETS="$POOL/users $POOL/users/root $POOL/backup $POOL/data $POOL/services $POOL/projects"
# and run: update-initramfs -u -k all

##apt-get install grub-common grub-pc grub-pc-bin grub2-common
# systemctl enable zfs-import-cache.service zfs-mount.service zfs-zed.service zfs-import.target zfs-volumes.target zfs.target
# systemctl start zfs-import-cache.service zfs-mount.service zfs-zed.service zfs-import.target zfs-volumes.target zfs.target

