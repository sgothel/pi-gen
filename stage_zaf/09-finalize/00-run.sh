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
    dpkg -P nfs-common rpcbind rsync autofs

    systemctl disable bluetooth
    systemctl mask bluetooth

    echo "i2c-bcm2708"  >> /etc/modules
    # echo "i2c-dev"    >> /etc/modules
    # echo "rtc-ds1307" >> /etc/modules

    if [ "${ROOTFS_RO}" = "1" ] ; then
        echo "i2c-bcm2708"  >> /etc/initramfs-tools/modules
        # echo "i2c-dev"    >> /etc/initramfs-tools/modules
        # echo "rtc-ds1307" >> /etc/initramfs-tools/modules
    fi

    cd /etc/wpa_supplicant
    rm -f wpa_supplicant.conf
    ln -s /boot/zafena/etc/wpa_supplicant/wpa_supplicant.conf .

    cd /etc/default
    rm -f ntpdate
    ln -s /boot/zafena/etc/ntpdate .

    cd /home/pi 
    rm -f data .xsession
    ln -s /boot/zafena/data data
    ln -s .xinitrc .xsession

    if [ "${ROOTFS_RO}" = "1" ] ; then
        # Rebuild `/data/sdcard` and initrd.img (flush stage2's produce)
        rm -rf /data/sdcard
        rm -f /boot/sys_arm64_000/initrd.img

        KVERSION=\$(ls /lib/modules/ | tail -n 1)
        echo "mkinitramfs for kernel version: \${KVERSION}"
        /usr/sbin/mkinitramfs -o /boot/sys_arm64_000/initrd.img \${KVERSION}

        mkdir -p                              /data/sdcard/zafena/data
        find  /boot/ -maxdepth 1 -type f \
              -exec cp -d --preserve=all \{\} /data/sdcard/ \;
        cp -a /boot/sys_arm64_000             /data/sdcard/
        cp -a /boot/zafena/etc                /data/sdcard/zafena/

        # Not working here: /boot/bootcode.bin: Function not implemented
        #fatattr +hs /boot/bootcode.bin
        #fatattr +hs /boot/config.txt
        #find /boot -maxdepth 1 -name \*.dat -exec fatattr +hs \{\} \;
        #find /boot -maxdepth 1 -name \*.elf -exec fatattr +hs \{\} \;
        #fatattr +hs /boot/sys_arm64_000
    fi
EOF

