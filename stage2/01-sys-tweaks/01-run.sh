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
#systemctl disable nfs-common
systemctl disable rpcbind
if [ "${ENABLE_SSH}" == "1" ]; then
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
#systemctl enable overlay_mount

systemctl disable overlay_mount
systemctl mask overlay_mount

# Setup unique system folder /boot/sys_arm64_000
mkdir -p /boot/sys_arm64_000
mv /boot/*.dtb /boot/COPYING.linux /boot/LICENCE.broadcom /boot/initrd.img /boot/sys_arm64_000/
mv /boot/issue.txt /boot/kernel8.img /boot/overlays /boot/rootfs.img /boot/sys_arm64_000/

mv /boot/config.txt /boot/config.txt.orig
mv /boot/cmdline.txt /boot/sys_arm64_000/cmdline.txt.orig
if [ -f /boot/initrd.img ]; then
    mv /boot/initrd.img /boot/sys_arm64_000/initrd.img.orig
fi

EOF

install -m 644 files/boot/sys_arm64_000/cmdline.txt 	"${ROOTFS_DIR}/boot/sys_arm64_000/"

install -m 644 files/boot/config.txt 	"${ROOTFS_DIR}/boot/"

install -m 755 files/initramfs/loop_rootfs 	"${ROOTFS_DIR}/etc/initramfs-tools/scripts/init-premount/"

# echo "squashfs" >> "${ROOTFS_DIR}/etc/modules"
echo "squashfs" >> "${ROOTFS_DIR}/etc/initramfs-tools/modules"

sed -i -e 's/MODULES=most/MODULES=dep/g' -e 's/BUSYBOX=auto/BUSYBOX=y/g' "${ROOTFS_DIR}/etc/initramfs-tools/initramfs.conf"

on_chroot << EOF
mkinitramfs -o /boot/sys_arm64_000/initrd.img
EOF

if [ "${USE_QEMU}" = "1" ]; then
	echo "enter QEMU mode"
	install -m 644 files/90-qemu.rules "${ROOTFS_DIR}/etc/udev/rules.d/"
	on_chroot << EOF
systemctl disable resize2fs_once
EOF
	echo "leaving QEMU mode"
else
	on_chroot << EOF
#systemctl enable resize2fs_once
systemctl disable resize2fs_once
EOF
	echo "leaving normal mode"
fi

on_chroot <<EOF
for GRP in input spi i2c gpio; do
	groupadd -f -r "\$GRP"
done
for GRP in adm dialout cdrom audio users sudo video games plugdev input gpio spi i2c netdev; do
  adduser $FIRST_USER_NAME \$GRP
done
EOF

on_chroot << EOF
setupcon --force --save-only -v
EOF

on_chroot << EOF
usermod --pass='*' root
EOF

rm -f "${ROOTFS_DIR}/etc/ssh/"ssh_host_*_key*
