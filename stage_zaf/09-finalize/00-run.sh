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

/bin/rm -f "${ROOTFS_DIR}/boot/config-rootfs_ro.txt"
/bin/rm -f "${ROOTFS_DIR}/boot/config-rootfs_rw.txt"
/bin/rm -f "${ROOTFS_DIR}/boot/sys_arm64_000/cmdline-rootfs_ro.txt"
/bin/rm -f "${ROOTFS_DIR}/boot/sys_arm64_000/cmdline-rootfs_rw.txt"

if [ "${ROOTFS_RO}" = "1" ] ; then
    /bin/cp -d  --preserve=timestamps  ../files.boot/config-rootfs_ro.txt "${ROOTFS_DIR}/boot/config.txt"
    /bin/cp -d  --preserve=timestamps  ../files.boot/config-rootfs_ro.txt "${ROOTFS_DIR}/boot/sys_arm64_000/config.txt"
    /bin/cp -d  --preserve=timestamps  ../files.boot/sys_arm64_000/cmdline-rootfs_ro.txt "${ROOTFS_DIR}/boot/sys_arm64_000/cmdline.txt"
else
    /bin/cp -d  --preserve=timestamps  ../files.boot/config-rootfs_rw.txt "${ROOTFS_DIR}/boot/config.txt"
    /bin/cp -d  --preserve=timestamps  ../files.boot/config-rootfs_rw.txt "${ROOTFS_DIR}/boot/sys_arm64_000/config.txt"
    /bin/cp -d  --preserve=timestamps  ../files.boot/sys_arm64_000/cmdline-rootfs_rw.txt "${ROOTFS_DIR}/boot/sys_arm64_000/cmdline.txt"
fi
mkdir -p                                                    "${ROOTFS_DIR}/boot/zafena/data"

/bin/cp -dR --preserve=timestamps     ../files.zafena_app/* "${ROOTFS_DIR}/boot/zafena/"

cat ../files.home/pi/.bashrc_startx                      >> "${ROOTFS_DIR}/home/pi/.bashrc"

echo $ZAFENA_VERSION                                     >  "${ROOTFS_DIR}/etc/zafena_version"

on_chroot << EOF
    cd /etc/default
    rm -f ntpdate
    ln -s /boot/zafena/etc/ntpdate .

    cd /home/pi 
    rm -f data .xsession
    ln -s /boot/zafena/data data
    ln -s .xinitrc .xsession
EOF
