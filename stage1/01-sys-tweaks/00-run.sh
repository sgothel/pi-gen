#!/bin/bash -e

install -d "${ROOTFS_DIR}/etc/systemd/system/getty@tty1.service.d"
install -m 644 files/noclear.conf "${ROOTFS_DIR}/etc/systemd/system/getty@tty1.service.d/noclear.conf"
install -v -m 644 files/fstab "${ROOTFS_DIR}/etc/fstab"

on_chroot << EOF
mkdir -p /data/etc/upper
mkdir -p /data/etc/work
mkdir -p /data/home/upper
mkdir -p /data/home/work
mkdir -p /data/srv/upper
mkdir -p /data/srv/work
mkdir -p /data/tmp/upper
mkdir -p /data/tmp/work
mkdir -p /data/var/upper
mkdir -p /data/var/work

# Memory ~1G -> Swap 2G; BUT slow and small sd-card 
# Use 200MB (Raspberry comes with 100MB default)
rm -f /data/swapfile
dd if=/dev/zero of=/data/swapfile bs=1M count=200
mkswap /data/swapfile
chmod 600 /data/swapfile

if ! id -u ${FIRST_USER_NAME} >/dev/null 2>&1; then
	adduser --disabled-password --gecos "" ${FIRST_USER_NAME}
fi
echo "${FIRST_USER_NAME}:${FIRST_USER_PASS}" | chpasswd
echo "root:root" | chpasswd
EOF


