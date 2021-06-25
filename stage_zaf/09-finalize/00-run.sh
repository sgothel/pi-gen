#!/bin/sh -e

# disabled for now
# tar -zxvf files/zafena.tar.gz -C "${ROOTFS_DIR}/"

cp -av ../files/*            "${ROOTFS_DIR}/"
cp -av ../files.elevator/*   "${ROOTFS_DIR}/"
cp -av ../files.zafena_app/* "${ROOTFS_DIR}/"

cp -av ../files/home/pi/splash.png "${ROOTFS_DIR}/usr/share/plymouth/themes/pix/splash.png"

cat ../files/home/pi/.bashrc_startx >> "${ROOTFS_DIR}/home/pi/.bashrc"

rm -fv "${ROOTFS_DIR}/etc/systemd/system/dbus-org.bluez.service"
rm -fv "${ROOTFS_DIR}/etc/systemd/system/bluetooth.target.wants/bluetooth.service"
# systemctl mask bluetooth
rm -fv "${ROOTFS_DIR}/etc/systemd/system/bluetooth.service"
ln -s /dev/null "${ROOTFS_DIR}/etc/systemd/system/bluetooth.service"

