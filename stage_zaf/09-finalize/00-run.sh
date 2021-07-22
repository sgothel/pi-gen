#!/bin/bash -e

# disabled for now
# tar -zxvf files/zafena.tar.gz -C "${ROOTFS_DIR}/"

fusrname=$(/usr/bin/stat -c %U ${BASE_DIR}/build.sh)
fgrpname=$(/usr/bin/stat -c %G ${BASE_DIR}/build.sh)

PRESERVE_ROOT="timestamps,mode,links"

chown -R root:root ../files.etc
chown -R 1000:1000 ../files.home
chown -R root:root ../files.elevator

/bin/cp -dR --preserve=$PRESERVE_ROOT ../files.etc/*        "${ROOTFS_DIR}/etc/"
/bin/cp -dR --preserve=$PRESERVE_ROOT ../files.home/*       "${ROOTFS_DIR}/home/"
/bin/cp -dR --preserve=$PRESERVE_ROOT ../files.elevator/*   "${ROOTFS_DIR}/"

/bin/cp -dR --preserve=timestamps     ../files.boot/*       "${ROOTFS_DIR}/boot/"

if [ "${TARGET_RASPI}" = "1" ]; then
    if [ "sys_arm64_000" != "${TARGET_ARCH}" ]; then
        /bin/mv -f "${ROOTFS_DIR}/boot/sys_arm64_000" "${ROOTFS_DIR}/boot/sys_${TARGET_ARCH}_000"
    fi

    /bin/rm -f "${ROOTFS_DIR}/boot/config-rootfs_ro.txt"
    /bin/rm -f "${ROOTFS_DIR}/boot/config-rootfs_rw.txt"
    /bin/rm -f "${ROOTFS_DIR}/boot/sys_${TARGET_ARCH}_000/cmdline-rootfs_ro.txt"
    /bin/rm -f "${ROOTFS_DIR}/boot/sys_${TARGET_ARCH}_000/cmdline-rootfs_rw.txt"

    if [ "${ROOTFS_RO}" = "1" ] ; then
        /bin/cp -d  --preserve=timestamps  ../files.boot/config-rootfs_ro.txt "${ROOTFS_DIR}/boot/config.txt"
        /bin/cp -d  --preserve=timestamps  ../files.boot/config-rootfs_ro.txt "${ROOTFS_DIR}/boot/sys_${TARGET_ARCH}_000/config.txt"
        /bin/cp -d  --preserve=timestamps  ../files.boot/sys_arm64_000/cmdline-rootfs_ro.txt "${ROOTFS_DIR}/boot/sys_${TARGET_ARCH}_000/cmdline.txt"
    else
        /bin/cp -d  --preserve=timestamps  ../files.boot/config-rootfs_rw.txt "${ROOTFS_DIR}/boot/config.txt"
        /bin/cp -d  --preserve=timestamps  ../files.boot/config-rootfs_rw.txt "${ROOTFS_DIR}/boot/sys_${TARGET_ARCH}_000/config.txt"
        /bin/cp -d  --preserve=timestamps  ../files.boot/sys_arm64_000/cmdline-rootfs_rw.txt "${ROOTFS_DIR}/boot/sys_${TARGET_ARCH}_000/cmdline.txt"
    fi
    sed -i "s/sys_arm64_000/sys_${TARGET_ARCH}_000/g"    "${ROOTFS_DIR}/boot/config.txt"
    sed -i "s/sys_arm64_000/sys_${TARGET_ARCH}_000/g"    "${ROOTFS_DIR}/boot/sys_${TARGET_ARCH}_000/config.txt"
else
    if [ "${ROOTFS_RO}" = "1" ] ; then
        install -m 644 files.boot/grub/custom-rootfs_ro.cfg  "${ROOTFS_DIR}/boot/grub/custom.cfg"
    else
        install -m 644 files.boot/grub/custom-rootfs_rw.cfg  "${ROOTFS_DIR}/boot/grub/custom.cfg"
    fi
    sed -i "s/sys_amd64_000/sys_${TARGET_ARCH}_000/g"    "${ROOTFS_DIR}/boot/grub/custom.cfg"
    cp "${ROOTFS_DIR}/boot/grub/custom.cfg"              "${ROOTFS_DIR}/boot/sys_${TARGET_ARCH}_000/"
    # Done in stage2 only for 'ROOTFS_RO'
    sed -i 's/GRUB_DEFAULT=.*$/GRUB_DEFAULT=loop_rootfs/g;s/GRUB_TIMEOUT=.*$/GRUB_TIMEOUT=0/g;s/#GRUB_TERMINAL=.*$/GRUB_TERMINAL=console/g;s/#GRUB_DISABLE_LINUX_UUID=.*$/GRUB_DISABLE_LINUX_UUID=true/g'                    "${ROOTFS_DIR}/etc/default/grub"
    echo "GRUB_DISABLE_LINUX_PARTUUID=true"           >> "${ROOTFS_DIR}/etc/default/grub"
    echo "GRUB_DISABLE_RECOVERY=true"                 >> "${ROOTFS_DIR}/etc/default/grub"
    rm -f                                                "${ROOTFS_DIR}/etc/grub.d/05_debian_theme"
    rm -f                                                "${ROOTFS_DIR}/etc/grub.d/10_linux"
    rm -f                                                "${ROOTFS_DIR}/etc/grub.d/20_linux_xen"
    rm -f                                                "${ROOTFS_DIR}/etc/grub.d/30_os-prober"
    rm -f                                                "${ROOTFS_DIR}/etc/grub.d/30_uefi-firmware"
    rm -f                                                "${ROOTFS_DIR}/etc/grub.d/20_memtest86"
    rm -f                                                "${ROOTFS_DIR}/etc/grub.d/20_memtest86+"
fi

mkdir -p                                                    "${ROOTFS_DIR}/boot/zafena/data"

/bin/cp -dR --preserve=timestamps     ../files.zafena_app/* "${ROOTFS_DIR}/boot/zafena/"

cat ../files.home/pi/.bashrc_startx                      >> "${ROOTFS_DIR}/home/pi/.bashrc"

echo $CUSTOM_VERSION                                     >  "${ROOTFS_DIR}/etc/zafena_version"
echo $CUSTOM_VERSION                                     >  "${ROOTFS_DIR}/boot/sys_${TARGET_ARCH}_000/zafena_version"

on_chroot << EOF
    plymouth-set-default-theme pix
EOF

/usr/bin/install -o 0 -g 0 -p ../files.home/pi/splash.png   "${ROOTFS_DIR}/usr/share/plymouth/themes/pix/"

on_chroot << EOF
    dpkg -P nfs-common rpcbind rsync autofs
    apt autoremove

    systemctl disable bluetooth
    systemctl mask bluetooth

    if [ "${TARGET_RASPI}" = "1" ]; then
        echo "i2c-bcm2708"  >> /etc/modules
        # echo "i2c-dev"    >> /etc/modules
        # echo "rtc-ds1307" >> /etc/modules
        if [ "${ROOTFS_RO}" = "1" ] ; then
            echo "i2c-bcm2708"  >> /etc/initramfs-tools/modules
            # echo "i2c-dev"    >> /etc/initramfs-tools/modules
            # echo "rtc-ds1307" >> /etc/initramfs-tools/modules
        fi
    fi

    if [ "${ROOTFS_RO}" = "1" ] ; then
        cd /etc/wpa_supplicant
        rm -f wpa_supplicant.conf
        ln -s /boot/zafena/etc/wpa_supplicant/wpa_supplicant.conf .

        cd /etc/default
        rm -f ntpdate
        ln -s /boot/zafena/etc/ntpdate .

        cd /home/pi 
        rm -f data
        ln -s /boot/zafena/data data
    else
        cp /boot/zafena/etc/wpa_supplicant/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf
        cp /boot/zafena/etc/ntpdate /etc/default/ntpdate

        cd /home/pi 
        rm -f data
        mkdir -p data
    fi
    rm -f .xsession .Xauthority
    ln -s .xinitrc .xsession

    KVERSION=\$(ls /lib/modules/ | tail -n 1)
    if [ "${ROOTFS_RO}" = "1" ] ; then
        # Rebuild `/data/sdcard` and initrd.img (flush stage2's produce)
        rm -rf /data/sdcard
        rm -f /boot/sys_${TARGET_ARCH}_000/initrd.img

        if [ "${TARGET_RASPI}" = "1" ]; then
            echo "mkinitramfs for kernel version: \${KVERSION}"
            /usr/sbin/mkinitramfs -o /boot/sys_${TARGET_ARCH}_000/initrd.img \${KVERSION}
        else
            update-initramfs -u -k \${KVERSION}
            if [ -f "/boot/initrd.img-\${KVERSION}" ] ; then
                mv -f "/boot/initrd.img-\${KVERSION}" /boot/sys_${TARGET_ARCH}_000/initrd.img
            fi
        fi

        mkdir -p                              /data/sdcard/zafena/data
        find  /boot/ -maxdepth 1 -type f \
              -exec cp -d --preserve=all \{\} /data/sdcard/ \;
        cp -a /boot/sys_${TARGET_ARCH}_000    /data/sdcard/
        cp -a /boot/zafena/etc                /data/sdcard/zafena/

        # Not working here: /boot/bootcode.bin: Function not implemented
        #fatattr +hs /boot/bootcode.bin
        #fatattr +hs /boot/config.txt
        #find /boot -maxdepth 1 -name \*.dat -exec fatattr +hs \{\} \;
        #find /boot -maxdepth 1 -name \*.elf -exec fatattr +hs \{\} \;
        #fatattr +hs /boot/sys_${TARGET_ARCH}_000
    else
        if [ "${TARGET_RASPI}" != "1" ]; then
            update-initramfs -u -k \${KVERSION}
        fi
    fi
    if [ "${TARGET_RASPI}" != "1" ]; then
        update-grub
        if [ "${ROOTFS_RO}" = "1" ] ; then
            grub-install --force-file-id --modules="gzio part_msdos fat" /dev/${NBD_DEV}
        else
            grub-install --force-file-id --modules="gzio part_msdos fat ext2" /dev/${NBD_DEV}
        fi

        # Remove storage device related 'search.fs_uuid' and allow multi homing
        rm -f /boot/grub/i386-pc/load.cfg
    fi
EOF

chown -R ${fusrname}:${fgrpname} ../files.etc
chown -R ${fusrname}:${fgrpname} ../files.home
chown -R ${fusrname}:${fgrpname} ../files.elevator

