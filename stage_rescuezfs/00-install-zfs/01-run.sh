#!/bin/bash -e

if [ "${TARGET_RASPI}" != "1" -a "${TARGET_ARCH}" = "amd64" ]; then
    mkdir -p "${ROOTFS_DIR}/root/zfs"
    cp -a files/root_zfs/* "${ROOTFS_DIR}/root/zfs/"

    mkdir -p "${ROOTFS_DIR}/etc/zfs"
    cp -a files/etc_zfs/*  "${ROOTFS_DIR}/etc/zfs/"

    on_chroot << EOF
        # Replace Debian ZFS packages and replace with vanilla latest release
        cd /root/zfs
        . ./zfs-remove.sh
        if [ "${RELEASE}" = "bookworm" ]; then
            . ./zfs-install-debian12-${TARGET_ARCH}.sh
        elif [ "${RELEASE}" = "bullseye" ]; then
            . ./zfs-install-debian11-${TARGET_ARCH}.sh
        elif [ "${RELEASE}" = "buster" ]; then
            . ./zfs-install-debian10-${TARGET_ARCH}.sh
        else
            echo "No ZFS packages provisioned for RELEASE ${RELEASE}"
            exit 2
        fi

        cat ./apt-preferences.d-local-pin-init >> /etc/apt/preferences.d/local-pin-init

        apt-get update
        apt-get clean

        KVERSION=\$(ls /lib/modules/ | tail -n 1)
        if [ "${ROOTFS_RO}" = "1" ]; then
            if [ "${TARGET_RASPI}" != "1" ]; then
                if [ -f "/boot/initrd.img-\${KVERSION}" ] ; then
                    mv -f "/boot/initrd.img-\${KVERSION}" /boot/sys_${TARGET_ARCH}_000/initrd.img
                fi
            fi
            rm -f /boot/sys_${TARGET_ARCH}_000/initrd.img

            echo "mkinitramfs for kernel version: \${KVERSION}"
            /usr/sbin/mkinitramfs -o /boot/sys_${TARGET_ARCH}_000/initrd.img \${KVERSION}

            rm -rf /data/sdcard
            mkdir -p /data/sdcard
            find  /boot/ -maxdepth 1 -type f \
                  -exec cp -d --preserve=all \{\} /data/sdcard/ \;
            cp -a /boot/sys_${TARGET_ARCH}_000 /data/sdcard/
        else
            if [ "${TARGET_RASPI}" != "1" ]; then
                update-initramfs -u -k \${KVERSION}
            fi
        fi
EOF
fi
