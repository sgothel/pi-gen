#!/bin/sh

set -x

cd /etc/initramfs-tools/
cp /home/pi/loop_rootfs scripts/init-premount/loop_rootfs 
mkinitramfs -o /home/pi/initrd.img 5.10.17-v8+
cp /home/pi/initrd.img /boot/sys_arm64_000/initrd.img 
cp /home/pi/initrd.img /boot/sys_arm64_001/initrd.img 
sync
