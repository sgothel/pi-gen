#! /bin/sh

ZFSDEBDIR=`readlink -f ./zfs-linux-2.4.2-1-debian13-amd64`

#skipped:
# kmod-zfs-6.12.90+deb13.1-amd64_2.4.2-1_amd64.deb
# kmod-zfs-devel-6.12.90+deb13.1-amd64_2.4.2-1_amd64.deb
# kmod-zfs-devel_2.4.2-1_amd64.deb
# libzfs7-devel_2.4.2-1_amd64.deb
# python3-pyzfs_2.4.2-1_amd64.deb
# zfs-2.4.2.tar.gz
# zfs-dracut_2.4.2-1_amd64.deb
# zfs-test_2.4.2-1_amd64.deb

if [ -e /etc/default/zfs ] ; then
    cp -a /etc/default/zfs /etc/default/zfs.cpy
fi

#apt-get install libnvpair1 libuutil1 libzpool2 libzfs2
dpkg -i $ZFSDEBDIR/libuutil3_2.4.2-1_amd64.deb
dpkg -i $ZFSDEBDIR/libnvpair3_2.4.2-1_amd64.deb
dpkg -i $ZFSDEBDIR/libzfs7_2.4.2-1_amd64.deb
dpkg -i $ZFSDEBDIR/libzpool7_2.4.2-1_amd64.deb
dpkg -i $ZFSDEBDIR/zfs-dkms_2.4.2-1_amd64.deb
dpkg -i $ZFSDEBDIR/zfs_2.4.2-1_amd64.deb
dpkg -i $ZFSDEBDIR/pam-zfs-key_2.4.2-1_amd64.deb
dpkg -i $ZFSDEBDIR/zfs-initramfs_2.4.2-1_amd64.deb

# apt-mark manual zfs-initramfs zfs zfs-dkms libzfs2 libzfs4 libzfs5 libzpool2 libzpool4 libzpool5 libuutil1 libuutil3 libnvpair1 libnvpair3
apt-mark manual zfs-initramfs zfs pam-zfs-key zfs-dkms libzfs7 libzpool7 libuutil3 libnvpair3

echo
echo
echo "CHECKLIST"
echo "- FIX /etc/default/zfs"
# ZFS_INITRD_ADDITIONAL_DATASETS="$POOL/users $POOL/users/root $POOL/backup $POOL/data $POOL/services $POOL/projects"

echo "- Check if all kernels have the zfs module (dkms)"
echo "  - dkms status"
echo "  - manually install for a missing (new) kernel, e.g."
echo "    - dkms install zfs/2.4.2 -k 6.12.90+deb13.1-amd64"
echo "- Update the initramfs"
echo "  - update-initramfs -u -k all"

##apt-get install grub-common grub-pc grub-pc-bin grub2-common
# systemctl enable zfs-import-cache.service zfs-mount.service zfs-zed.service zfs-import.target zfs-volumes.target zfs.target
# systemctl start zfs-import-cache.service zfs-mount.service zfs-zed.service zfs-import.target zfs-volumes.target zfs.target

