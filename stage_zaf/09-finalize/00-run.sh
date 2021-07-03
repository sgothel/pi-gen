#!/bin/bash -e

# disabled for now
# tar -zxvf files/zafena.tar.gz -C "${ROOTFS_DIR}/"

PRESERVE_ROOT="timestamps,mode,links"

chown -R root:root ../files.etc
chown -R 1000:1000 ../files.home
chown -R root:root ../files.elevator

/bin/cp -dR --preserve=$PRESERVE_ROOT ../files.etc/*        "${ROOTFS_DIR}/etc/"
/bin/cp -dR --preserve=$PRESERVE_ROOT ../files.home/*       "${ROOTFS_DIR}/home/"
/bin/cp -dR --preserve=$PRESERVE_ROOT ../files.elevator/*   "${ROOTFS_DIR}/"
/usr/bin/install -o 0 -g 0 -p ../files.home/pi/splash.png   "${ROOTFS_DIR}/usr/share/plymouth/themes/pix/"

/bin/cp -dR --preserve=timestamps     ../files.boot/*       "${ROOTFS_DIR}/boot/"
mkdir -p                                                    "${ROOTFS_DIR}/boot/zafena/data"

/bin/cp -dR --preserve=timestamps     ../files.zafena_app/* "${ROOTFS_DIR}/boot/zafena/"

cat ../files.home/pi/.bashrc_startx                      >> "${ROOTFS_DIR}/home/pi/.bashrc"

echo $ZAFENA_VERSION                                     >  "${ROOTFS_DIR}/etc/zafena_version"

# Implied above by copying files.etc
# install -m 600 files/ssh/ssh_host_dsa_key          "${ROOTFS_DIR}/etc/ssh"
# install -m 600 files/ssh/ssh_host_ecdsa_key        "${ROOTFS_DIR}/etc/ssh"
# install -m 600 files/ssh/ssh_host_ed25519_key      "${ROOTFS_DIR}/etc/ssh"
# install -m 600 files/ssh/ssh_host_rsa_key          "${ROOTFS_DIR}/etc/ssh"

# install -m 644 files/ssh/ssh_host_dsa_key.pub      "${ROOTFS_DIR}/etc/ssh"
# install -m 644 files/ssh/ssh_host_ecdsa_key.pub    "${ROOTFS_DIR}/etc/ssh"
# install -m 644 files/ssh/ssh_host_ed25519_key.pub  "${ROOTFS_DIR}/etc/ssh"
# install -m 644 files/ssh/ssh_host_rsa_key.pub      "${ROOTFS_DIR}/etc/ssh"

on_chroot << EOF
    cd /etc/default
    rm -f ntpdate
    ln -s /boot/zafena/etc/ntpdate .

    systemctl disable regenerate_ssh_host_keys
    systemctl mask regenerate_ssh_host_keys

    cd /home/pi 
    rm -f data .xsession
    ln -s /boot/zafena/data data
    ln -s .xinitrc .xsession
EOF
