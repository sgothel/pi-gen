#!/bin/bash -e

if [ "${ROOTFS_RO}" = "1" ] ; then
    install -v -m 644 files/fstab-rootfs_ro "${ROOTFS_DIR}/etc/fstab"
else
    install -v -m 644 files/fstab-rootfs_rw "${ROOTFS_DIR}/etc/fstab"
fi
install -m 644 files/overlay_mount.service          "${ROOTFS_DIR}/lib/systemd/system/"
install -m 755 files/overlay_mount	                "${ROOTFS_DIR}/etc/init.d/"
sed -i "s/OVERLAY_TMPFS_SIZE/${ROOTFS_RO_OVERLAY_TMPFS_SIZE}/g" "${ROOTFS_DIR}/etc/init.d/overlay_mount"

install -m 644 files/rotatelog_init_rootfs.service	"${ROOTFS_DIR}/lib/systemd/system/"
install -m 755 files/rotatelog_init_rootfs	        "${ROOTFS_DIR}/etc/init.d/"

install -m 644 files/resize2fs_once.service	        "${ROOTFS_DIR}/lib/systemd/system/"
install -m 755 files/resize2fs_once	                "${ROOTFS_DIR}/etc/init.d/"

install -d				            "${ROOTFS_DIR}/etc/systemd/system/rc-local.service.d"
install -m 644 files/ttyoutput.conf	"${ROOTFS_DIR}/etc/systemd/system/rc-local.service.d/"

if [ "${TARGET_RASPI}" = "1" ]; then
    install -m 644 files/50raspi		"${ROOTFS_DIR}/etc/apt/apt.conf.d/"
fi

install -m 644 files/console-setup   	"${ROOTFS_DIR}/etc/default/"

install -m 755 files/rc.local		"${ROOTFS_DIR}/etc/"

if [ -n "${PUBKEY_SSH_FIRST_USER}" ]; then
	install -v -m 0700 -o 1000 -g 1000 -d "${ROOTFS_DIR}"/home/"${FIRST_USER_NAME}"/.ssh
	echo "${PUBKEY_SSH_FIRST_USER}" >"${ROOTFS_DIR}"/home/"${FIRST_USER_NAME}"/.ssh/authorized_keys
    if [ -n "${PUBKEY2_SSH_FIRST_USER}" ]; then
        echo "${PUBKEY2_SSH_FIRST_USER}" >>"${ROOTFS_DIR}"/home/"${FIRST_USER_NAME}"/.ssh/authorized_keys
    fi
	chown 1000:1000 "${ROOTFS_DIR}"/home/"${FIRST_USER_NAME}"/.ssh/authorized_keys
	chmod 0600 "${ROOTFS_DIR}"/home/"${FIRST_USER_NAME}"/.ssh/authorized_keys
fi

if [ "${PUBKEY_ONLY_SSH}" = "1" ]; then
	sed -i -Ee 's/^#?[[:blank:]]*PubkeyAuthentication[[:blank:]]*no[[:blank:]]*$/PubkeyAuthentication yes/
s/^#?[[:blank:]]*PasswordAuthentication[[:blank:]]*yes[[:blank:]]*$/PasswordAuthentication no/' "${ROOTFS_DIR}"/etc/ssh/sshd_config
fi

on_chroot << EOF
    if [ "${TARGET_RASPI}" = "1" ]; then
        systemctl disable hwclock.sh
        plymouth-set-default-theme pix
    else
        # No packages, still make sure
        systemctl disable plymouth
        systemctl mask plymouth
    fi

    if [ "${ROOTFS_RO}" = "1" ] ; then
        # /boot and ROOT are mounted via our 'loop_rootfs' script
        # without having a live mapping in /etc/fstab.
        systemctl disable systemd-remount-fs
        systemctl mask systemd-remount-fs
    else
        sed -i "s/vfat/${BOOT_FSTYPE}/g" /etc/fstab
    fi

    systemctl disable rsync
    systemctl mask rsync
    systemctl disable nfs-common
    systemctl mask nfs-common
    systemctl disable rpcbind
    systemctl mask rpcbind

    if [ "${TARGET_RASPI}" != "1" ]; then
        # ensure sysfsutils is enabled at boot
        systemctl is-enabled sysfsutils
    fi

    if [ "${ENABLE_SSH}" == "1" ]; then
        systemctl unmask ssh
        systemctl enable ssh
    else
        systemctl disable ssh
        systemctl mask ssh
    fi
    systemctl disable regenerate_ssh_host_keys
    systemctl mask regenerate_ssh_host_keys

    if [ "${ROOTFS_RO}" = "1" ] ; then
        sed -i -e 's/^D \/tmp/#D \/tmp/g' /usr/lib/tmpfiles.d/tmp.conf

        systemctl unmask overlay_mount
        systemctl enable overlay_mount

        systemctl unmask rotatelog_init_rootfs
        systemctl enable rotatelog_init_rootfs
    else
        systemctl disable overlay_mount
        systemctl mask    overlay_mount

        systemctl disable rotatelog_init_rootfs
        systemctl mask    rotatelog_init_rootfs
    fi

    # Setup unique system folder /boot/sys_arm64_000
    mkdir -p /boot/sys_${TARGET_ARCH}_000

    find /boot -maxdepth 1 -name \*.dtb -exec mv \{\} /boot/sys_${TARGET_ARCH}_000/ \;

    find /boot -maxdepth 1 -name kernel\*.img -exec mv \{\} /boot/sys_${TARGET_ARCH}_000/ \;

    for i in /boot/COPYING.linux /boot/LICENCE.broadcom \
             /boot/issue.txt /boot/rootfs.img ; do
        if [ -f "\${i}" ]; then
             mv "\${i}" /boot/sys_${TARGET_ARCH}_000/
        fi
    done
    
    if [ -d /boot/overlays ] ; then
        mv /boot/overlays /boot/sys_${TARGET_ARCH}_000/
    fi

    for i in /boot/config.txt /boot/cmdline.txt /boot/initrd.img ; do
        if [ -f "\${i}" ]; then
             mv "\${i}" /boot/sys_${TARGET_ARCH}_000/\`basename \${i}\`.orig
        fi
    done

    if [ "${ROOTFS_RO}" = "1" ] ; then
        # Allow this partition to be found by loop_rootfs
        touch /boot/loop_rootfs.id

        systemctl disable resize2fs_once
        systemctl mask resize2fs_once

        systemctl disable apt-daily
        systemctl mask apt-daily
        systemctl disable apt-daily.timer
        systemctl mask apt-daily.timer
        systemctl disable apt-daily-upgrade.timer
        systemctl mask apt-daily-upgrade.timer

        systemctl disable logrotate.timer
        systemctl mask logrotate.time
        systemctl disable man-db.timer
        systemctl mask man-db.timer

        sed -i -e 's/#Storage=auto/Storage=volatile/g;s/#Compress=yes/Compress=yes/g;s/#RuntimeMaxUse=/RuntimeMaxUse=1M/g;s/#ForwardToSyslog=yes/ForwardToSyslog=no/g;s/#ForwardToKMsg=no/ForwardToKMsg=no/g;s/#ForwardToConsole=no/ForwardToConsole=no/g;s/#ForwardToWall=yes/ForwardToWall=no/g;s/#TTYPath=\/dev\/console/TTYPath=\/dev\/tty3/g' /etc/systemd/journald.conf

        if [ "${TARGET_RASPI}" = "1" ]; then
            sed -i -e 's/MODULES=most/MODULES=dep/g;s/BUSYBOX=auto/BUSYBOX=y/g;s/COMPRESS=gzip/COMPRESS=lzop/g' /etc/initramfs-tools/initramfs.conf
        else
            sed -i -e 's/BUSYBOX=auto/BUSYBOX=y/g;s/COMPRESS=gzip/COMPRESS=lzop/g' /etc/initramfs-tools/initramfs.conf
        fi

        # Adding both codepage 437 (FAT_CODEPAGE) and 850 to be safe, as fsck.vfat may misbehave
        if [ "${TARGET_RASPI}" = "1" ]; then
            KMODULES="nls_cp437 nls_cp850 nls_ascii squashfs fat vfat drm vc4"
        else
            KMODULES="nls_cp437 nls_cp850 nls_ascii fat vfat squashfs loop usb-common usbcore libahci ahci libata scsi_mod sd_mod usb-storage drm"
        fi
        for i in \${KMODULES} ; do
            echo "\$i" >> /etc/modules
            echo "\$i" >> /etc/initramfs-tools/modules
        done
    else
        systemctl unmask resize2fs_once
        systemctl enable resize2fs_once
    fi
EOF

if [ "${ROOTFS_RO}" = "1" ] ; then
    if [ "${TARGET_RASPI}" = "1" ]; then
        install -m 644 files/boot/config-rootfs_ro.txt 	     "${ROOTFS_DIR}/boot/config.txt"
        install -m 644 files/boot/config-rootfs_ro.txt 	     "${ROOTFS_DIR}/boot/sys_${TARGET_ARCH}_000/config.txt"
        install -m 644 files/boot/sys_arm64_000/cmdline-rootfs_ro.txt  "${ROOTFS_DIR}/boot/sys_${TARGET_ARCH}_000/cmdline.txt"
        sed -i "s/sys_arm64_000/sys_${TARGET_ARCH}_000/g"    "${ROOTFS_DIR}/boot/config.txt"
        sed -i "s/sys_arm64_000/sys_${TARGET_ARCH}_000/g"    "${ROOTFS_DIR}/boot/sys_${TARGET_ARCH}_000/config.txt"
        if [ "${TARGET_ARCH}" = "armhf" ]; then
            sed -i "s/arm_64bit=1/# arm_64bit=1/g"           "${ROOTFS_DIR}/boot/config.txt"
            sed -i "s/arm_64bit=1/# arm_64bit=1/g"           "${ROOTFS_DIR}/boot/sys_${TARGET_ARCH}_000/config.txt"
        fi
    else
        install -m 644 files/grub/custom-rootfs_ro.cfg       "${ROOTFS_DIR}/boot/grub/custom.cfg"
        sed -i "s/sys_amd64_000/sys_${TARGET_ARCH}_000/g"    "${ROOTFS_DIR}/boot/grub/custom.cfg"
        cp "${ROOTFS_DIR}/boot/grub/custom.cfg"              "${ROOTFS_DIR}/boot/sys_${TARGET_ARCH}_000/"
        sed -i 's/GRUB_DEFAULT=.*$/GRUB_DEFAULT=loop_rootfs/g;s/GRUB_TIMEOUT=.*$/GRUB_TIMEOUT=0/g;s/#GRUB_TERMINAL=.*$/GRUB_TERMINAL=console/g;s/#GRUB_DISABLE_LINUX_UUID=.*$/GRUB_DISABLE_LINUX_UUID=true/g'                    "${ROOTFS_DIR}/etc/default/grub"
        echo "GRUB_DISABLE_LINUX_PARTUUID=true"           >> "${ROOTFS_DIR}/etc/default/grub"
        echo "GRUB_DISABLE_RECOVERY=true"                 >> "${ROOTFS_DIR}/etc/default/grub"
        rm -f                                                "${ROOTFS_DIR}/etc/grub.d/05_debian_theme"
        rm -f                                                "${ROOTFS_DIR}/etc/grub.d/10_linux"
        rm -f                                                "${ROOTFS_DIR}/etc/grub.d/20_linux_xen"
        rm -f                                                "${ROOTFS_DIR}/etc/grub.d/30_os-prober"
        rm -f                                                "${ROOTFS_DIR}/etc/grub.d/30_uefi-firmware"
        rm -f                                                "${ROOTFS_DIR}/etc/grub.d/20_memtest86"
        rm -f                                                "${ROOTFS_DIR}/etc/grub.d/20_memtest86+"
    fi

    install -m 755 files/initramfs/loop_rootfs-premount 	"${ROOTFS_DIR}/etc/initramfs-tools/scripts/init-premount/loop_rootfs"
    sed -i "s/sys_arm64_000/sys_${TARGET_ARCH}_000/g" "${ROOTFS_DIR}/etc/initramfs-tools/scripts/init-premount/loop_rootfs"
    sed -i "s/BOOT_FSTYPE=.*$/BOOT_FSTYPE=${BOOT_FSTYPE}/g" "${ROOTFS_DIR}/etc/initramfs-tools/scripts/init-premount/loop_rootfs"
    sed -i "s/BOOT_FSOPTIONS=.*$/BOOT_FSOPTIONS=${BOOT_FSOPTIONS}/g" "${ROOTFS_DIR}/etc/initramfs-tools/scripts/init-premount/loop_rootfs"
    if [ "${TARGET_RASPI}" != "1" ]; then
        sed -i 's/USES_RASPI_CONFIG=1/USES_RASPI_CONFIG=0/g' "${ROOTFS_DIR}/etc/initramfs-tools/scripts/init-premount/loop_rootfs"
    fi
    install -m 755 files/initramfs/loop_rootfs-bottom 	"${ROOTFS_DIR}/etc/initramfs-tools/scripts/init-bottom/loop_rootfs"
    install -m 755 files/initramfs/fsck_custom 	"${ROOTFS_DIR}/etc/initramfs-tools/hooks/"
    install -m 755 files/initramfs/extra_execs  "${ROOTFS_DIR}/etc/initramfs-tools/hooks/"
else
    # Mutable rootfs
    if [ "${TARGET_RASPI}" = "1" ]; then
        install -m 644 files/boot/config-rootfs_rw.txt 	     "${ROOTFS_DIR}/boot/config.txt"
        install -m 644 files/boot/config-rootfs_rw.txt 	     "${ROOTFS_DIR}/boot/sys_${TARGET_ARCH}_000/config.txt"
        install -m 644 files/boot/sys_arm64_000/cmdline-rootfs_rw.txt  "${ROOTFS_DIR}/boot/sys_${TARGET_ARCH}_000/cmdline.txt"
        sed -i "s/sys_arm64_000/sys_${TARGET_ARCH}_000/g"    "${ROOTFS_DIR}/boot/config.txt"
        sed -i "s/sys_arm64_000/sys_${TARGET_ARCH}_000/g"    "${ROOTFS_DIR}/boot/sys_${TARGET_ARCH}_000/config.txt"
        if [ "${TARGET_ARCH}" = "armhf" ]; then
            sed -i "s/arm_64bit=1/# arm_64bit=1/g"               "${ROOTFS_DIR}/boot/config.txt"
            sed -i "s/arm_64bit=1/# arm_64bit=1/g"               "${ROOTFS_DIR}/boot/sys_${TARGET_ARCH}_000/config.txt"
        fi
    else
        sed -i 's/quiet//g'                                  "${ROOTFS_DIR}/etc/default/grub"
    fi
fi

if [ "${USE_QEMU}" = "1" ]; then
	echo "enter QEMU mode"
	install -m 644 files/90-qemu.rules "${ROOTFS_DIR}/etc/udev/rules.d/"
	echo "leaving QEMU mode"
fi

on_chroot <<EOF
    for GRP in input spi i2c gpio; do
        groupadd -f -r "\$GRP"
    done
    for GRP in adm dialout cdrom audio users sudo video games plugdev input gpio spi i2c netdev; do
      adduser $FIRST_USER_NAME \$GRP
    done

    setupcon --force --save-only -v
    usermod --pass='*' root

    KVERSION=\$(ls /lib/modules/ | tail -n 1)
    if [ "${ROOTFS_RO}" = "1" ]; then
        if [ "${TARGET_RASPI}" != "1" ]; then
            if [ -f "/boot/vmlinuz-\${KVERSION}" ] ; then
                mv -f "/boot/vmlinuz-\${KVERSION}" /boot/sys_${TARGET_ARCH}_000/vmlinuz
            fi
            if [ -f "/boot/initrd.img-\${KVERSION}" ] ; then
                mv -f "/boot/initrd.img-\${KVERSION}" /boot/sys_${TARGET_ARCH}_000/initrd.img
            fi
            if [ -f "/boot/config-\${KVERSION}" ] ; then
                # keep copy in location as required by mkinitramfs (debian 12)
                cp -a "/boot/config-\${KVERSION}" /boot/sys_${TARGET_ARCH}_000/config
            fi
            if [ -f "/boot/System.map-\${KVERSION}" ] ; then
                mv -f "/boot/System.map-\${KVERSION}" /boot/sys_${TARGET_ARCH}_000/System.map
            fi
        fi
        rm -f /boot/sys_${TARGET_ARCH}_000/initrd.img

        echo "mkinitramfs for kernel version: \${KVERSION}"
        /usr/sbin/mkinitramfs -o /boot/sys_${TARGET_ARCH}_000/initrd.img \${KVERSION}

        mkdir -p /data/sdcard
        find  /boot/ -maxdepth 1 -type f \
              -exec cp -d --preserve=all \{\} /data/sdcard/ \;
        cp -a /boot/sys_${TARGET_ARCH}_000 /data/sdcard/
    else
        if [ "${TARGET_RASPI}" != "1" ]; then
            update-initramfs -u -k \${KVERSION}
        fi
    fi
    if [ "${TARGET_RASPI}" != "1" ]; then
        update-grub
        if [ "${ROOTFS_RO}" = "1" ] ; then
            grub-install --force-file-id --modules="gzio part_msdos fat" /dev/${NBD_DEV}
        else
            grub-install --force-file-id --modules="gzio part_msdos fat ext2" /dev/${NBD_DEV}
        fi

        # Remove storage device related search.fs_uuid and allow multi homing
        rm -f /boot/grub/i386-pc/load.cfg
    fi
EOF

