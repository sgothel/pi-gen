#!/bin/bash -e

echo "background=/boot/grub/theme/desktop-4x3.svg" >> "${ROOTFS_DIR}/etc/lightdm/lightdm-gtk-greeter.conf"

on_chroot << EOF
    rm -f /etc/alternatives/desktop-background
    ln -s /boot/grub/theme/desktop-4x3.svg /etc/alternatives/desktop-background
EOF

