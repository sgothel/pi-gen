#!/bin/bash -e

#
# Just mod a little for memtest86+.bin
#

on_chroot << EOF
    find /boot -maxdepth 1 -name memtest\* -exec mv \{\} /boot/sys_${TARGET_ARCH}_000/ \;
EOF

if [ "${ROOTFS_RO}" = "1" ] ; then
    if [ "${TARGET_RASPI}" != "1" ]; then
        cat files/grub/custom.cfg                         >> "${ROOTFS_DIR}/boot/grub/custom.cfg"
        sed -i "s/sys_amd64_000/sys_${TARGET_ARCH}_000/g"    "${ROOTFS_DIR}/boot/grub/custom.cfg"
        cp "${ROOTFS_DIR}/boot/grub/custom.cfg"              "${ROOTFS_DIR}/boot/sys_${TARGET_ARCH}_000/"
        sed -i 's/GRUB_TIMEOUT=.*$/GRUB_TIMEOUT=5/g'         "${ROOTFS_DIR}/etc/default/grub"
        rm -f                                                "${ROOTFS_DIR}/etc/grub.d/20_memtest86"
        rm -f                                                "${ROOTFS_DIR}/etc/grub.d/20_memtest86+"
    fi
fi

on_chroot <<EOF
    if [ "${ROOTFS_RO}" = "1" ]; then
        mkdir -p /data/sdcard
        cp -a /boot/sys_${TARGET_ARCH}_000 /data/sdcard/
    fi
    if [ "${TARGET_RASPI}" != "1" ]; then
        # Update grub.cfg for (1 ROOTFS_RO): timeout=5 or (2) normal memtest86+.bin menu entries
        update-grub

        # Remove storage device related 'search.fs_uuid' and allow multi homing
        rm -f /boot/grub/i386-pc/load.cfg
    fi
EOF

