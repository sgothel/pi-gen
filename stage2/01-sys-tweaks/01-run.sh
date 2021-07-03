#!/bin/bash -e

install -m 644 files/overlay_mount.service	"${ROOTFS_DIR}/lib/systemd/system/"
install -m 755 files/overlay_mount	        "${ROOTFS_DIR}/etc/init.d/"

install -m 755 files/resize2fs_once	"${ROOTFS_DIR}/etc/init.d/"

install -d				"${ROOTFS_DIR}/etc/systemd/system/rc-local.service.d"
install -m 644 files/ttyoutput.conf	"${ROOTFS_DIR}/etc/systemd/system/rc-local.service.d/"

install -m 644 files/50raspi		"${ROOTFS_DIR}/etc/apt/apt.conf.d/"

install -m 644 files/console-setup   	"${ROOTFS_DIR}/etc/default/"

install -m 755 files/rc.local		"${ROOTFS_DIR}/etc/"

if [ -n "${PUBKEY_SSH_FIRST_USER}" ]; then
	install -v -m 0700 -o 1000 -g 1000 -d "${ROOTFS_DIR}"/home/"${FIRST_USER_NAME}"/.ssh
	echo "${PUBKEY_SSH_FIRST_USER}" >"${ROOTFS_DIR}"/home/"${FIRST_USER_NAME}"/.ssh/authorized_keys
	chown 1000:1000 "${ROOTFS_DIR}"/home/"${FIRST_USER_NAME}"/.ssh/authorized_keys
	chmod 0600 "${ROOTFS_DIR}"/home/"${FIRST_USER_NAME}"/.ssh/authorized_keys
fi

if [ "${PUBKEY_ONLY_SSH}" = "1" ]; then
	sed -i -Ee 's/^#?[[:blank:]]*PubkeyAuthentication[[:blank:]]*no[[:blank:]]*$/PubkeyAuthentication yes/
s/^#?[[:blank:]]*PasswordAuthentication[[:blank:]]*yes[[:blank:]]*$/PasswordAuthentication no/' "${ROOTFS_DIR}"/etc/ssh/sshd_config
fi

on_chroot << EOF
    systemctl disable hwclock.sh

    systemctl disable nfs-common
    systemctl mask nfs-common
    systemctl disable rpcbind
    systemctl mask rpcbind

    if [ "\${ENABLE_SSH}" == "1" ]; then
        systemctl enable ssh
    else
        systemctl disable ssh
    fi
    systemctl enable regenerate_ssh_host_keys

    #mkdir -p /data/overlay_a
    #cd /data/overlay_a
    #mkdir -p etc/upper etc/work home/upper home/work srv/upper srv/work tmp/upper tmp/work var/upper var/work
    #
    #mkdir -p /data/overlay_b
    #cd /data/overlay_b
    #mkdir -p etc/upper etc/work home/upper home/work srv/upper srv/work tmp/upper tmp/work var/upper var/work
    #
    #cd /data
    #ln -s overlay_a overlay
    #

    sed -i -e 's/^D \/tmp/#D \/tmp/g' /usr/lib/tmpfiles.d/tmp.conf

    systemctl unmask overlay_mount
    systemctl enable overlay_mount

    #systemctl disable overlay_mount
    #systemctl mask overlay_mount

    # Setup unique system folder /boot/sys_arm64_000
    mkdir -p /boot/sys_arm64_000

    find /boot -maxdepth 1 -name \*.dtb -exec mv \{\} /boot/sys_arm64_000/ \;

    find /boot -maxdepth 1 -name kernel\*.img -exec mv \{\} /boot/sys_arm64_000/ \;

    for i in /boot/COPYING.linux /boot/LICENCE.broadcom \
             /boot/issue.txt /boot/rootfs.img ; do
        if [ -f "\${i}" ]; then
             mv "\${i}" /boot/sys_arm64_000/
        fi
    done

    mv /boot/overlays /boot/sys_arm64_000/

    for i in /boot/config.txt /boot/cmdline.txt /boot/initrd.img ; do
        if [ -f "\${i}" ]; then
             mv "\${i}" /boot/sys_arm64_000/"\${i}.orig"
        fi
    done

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

    systemctl disable bluetooth
    systemctl mask bluetooth

    sed -i -e 's/#Storage=auto/Storage=volatile/g;s/#Compress=yes/Compress=yes/g;s/#RuntimeMaxUse=/RuntimeMaxUse=1M/g;s/#ForwardToSyslog=yes/ForwardToSyslog=no/g;s/#ForwardToWall=yes/ForwardToWall=no/g' /etc/systemd/journald.conf

    sed -i -e 's/MODULES=most/MODULES=dep/g;s/BUSYBOX=auto/BUSYBOX=y/g' /etc/initramfs-tools/initramfs.conf

    echo "squashfs"     >> /etc/modules
    echo "i2c-bcm2708"  >> /etc/modules
    # echo "i2c-dev"    >> /etc/modules
    # echo "rtc-ds1307" >> /etc/modules

    echo "squashfs"     >> /etc/initramfs-tools/modules
    echo "i2c-bcm2708"  >> /etc/initramfs-tools/modules
    # echo "i2c-dev"    >> /etc/initramfs-tools/modules
    # echo "rtc-ds1307" >> /etc/initramfs-tools/modules
EOF

install -m 644 files/boot/sys_arm64_000/cmdline.txt 	"${ROOTFS_DIR}/boot/sys_arm64_000/"

install -m 644 files/boot/config.txt 	"${ROOTFS_DIR}/boot/"

install -m 755 files/initramfs/loop_rootfs 	"${ROOTFS_DIR}/etc/initramfs-tools/scripts/init-premount/"
install -m 755 files/initramfs/fsck_custom 	"${ROOTFS_DIR}/etc/initramfs-tools/hooks/"

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
    echo "mkinitramfs for kernel version: \${KVERSION}"
    /usr/sbin/mkinitramfs -o /boot/sys_arm64_000/initrd.img \${KVERSION}
EOF

rm -f "${ROOTFS_DIR}/etc/ssh/"ssh_host_*_key*

