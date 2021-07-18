
# old stretch/buster/bullseye stuff ..
dpkg -r --force-all zfs-zed zfs-initramfs zfsutils-linux zfs-dkms libzfs2linux libzpool2linux libuutil1linux libnvpair1linux spl spl-dkms
dpkg -P --force-all zfs-zed zfs-initramfs zfsutils-linux zfs-dkms libzfs2linux libzpool2linux libuutil1linux libnvpair1linux spl spl-dkms

dpkg -r --force-all simplesnap zfssnap
dpkg -P --force-all simplesnap zfssnap

# 0.7.3 - 0.8.4 ??
dpkg -r --force-all libzfs2-devel
dpkg -P --force-all libzfs2-devel

dpkg -r --force-all zfs-initramfs zfs zfs-dkms libzfs2 libzpool2 libuutil1 libnvpair1 spl spl-dkms
dpkg -P --force-all zfs-initramfs zfs zfs-dkms libzfs2 libzpool2 libuutil1 libnvpair1 spl spl-dkms

dpkg -r --force-all zfs-dracut zfs-test
dpkg -P --force-all zfs-dracut zfs-test

#dpkg -r grub-common grub-pc grub-pc-bin grub2-common
