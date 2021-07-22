#!/bin/sh

#dest="root@zaf502"
dest="root@virtl09"

scp extra_execs          ${dest}:/etc/initramfs-tools/hooks/
scp loop_rootfs-bottom   ${dest}:/etc/initramfs-tools/scripts/init-bottom/loop_rootfs
scp loop_rootfs-premount ${dest}:/etc/initramfs-tools/scripts/init-premount/loop_rootfs
echo mkinitramfs -o /boot/sys_arm64_000/initrd.img 5.10.17-v8+
