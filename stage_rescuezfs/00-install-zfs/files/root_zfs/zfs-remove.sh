
if [ -e /etc/default/zfs ] ; then
    cp -a /etc/default/zfs /etc/default/zfs.cpy
fi

dpkg -r --force-all zfs-initramfs zfs pam-zfs-key zfs-dkms libzpool4 libzpool5 libzfs4 libzfs5 libnvpair3 libuutil3
dpkg -P --force-all zfs-initramfs zfs pam-zfs-key zfs-dkms libzpool4 libzpool5 libzfs4 libzfs5 libnvpair3 libuutil3

#dpkg -r grub-common grub-pc grub-pc-bin grub2-common
