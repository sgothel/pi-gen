#!/bin/sh -e

# disabled for now
# tar -zxvf files/zafena.tar.gz -C "${ROOTFS_DIR}/"

cp -av ../files/*            "${ROOTFS_DIR}/"
cp -av ../files.elevator/*   "${ROOTFS_DIR}/"
cp -av ../files.zafena_app/* "${ROOTFS_DIR}/"

rm -fv /etc/systemd/system/dbus-org.bluez.service
rm -fv /etc/systemd/system/bluetooth.target.wants/bluetooth.service
# systemctl mask bluetooth
ln -s /dev/null /etc/systemd/system/bluetooth.service

