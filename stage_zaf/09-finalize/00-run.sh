#!/bin/bash -e

# disabled for now
# tar -zxvf files/zafena.tar.gz -C "${ROOTFS_DIR}/"

fusrname=$(/usr/bin/stat -c %U ${BASE_DIR}/build.sh)
fgrpname=$(/usr/bin/stat -c %G ${BASE_DIR}/build.sh)

PRESERVE_ROOT="timestamps,mode,links"

DEBIAN_FRONTEND=noninteractive
APT_GET_INSTALL_OPTS='-o APT::Acquire::Retries=3 -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"'

/bin/chown -R root:root ../files.etc
/bin/chown -R 1000:1000 ../files.home
/bin/chown -R root:root ../files.elevator

/bin/cp -dR --preserve=$PRESERVE_ROOT ../files.etc/*        "${ROOTFS_DIR}/etc/"
/bin/cp -dR --preserve=$PRESERVE_ROOT ../files.home/*       "${ROOTFS_DIR}/home/"
/bin/cp -dR --preserve=$PRESERVE_ROOT ../files.elevator/*   "${ROOTFS_DIR}/"

/bin/cp -d --preserve=timestamps ../files.boot/config.xml         "${ROOTFS_DIR}/boot/"
/bin/cp -d --preserve=timestamps ../files.boot/config-example.xml "${ROOTFS_DIR}/boot/"
/bin/cp -dR --preserve=timestamps ../files.boot/grub              "${ROOTFS_DIR}/boot/"
/bin/cp -dR --preserve=timestamps ../files.boot/zafena            "${ROOTFS_DIR}/boot/"

if [ "${TARGET_RASPI}" = "1" ]; then
    /bin/mkdir -p                                                           "${ROOTFS_DIR}/boot/sys_${TARGET_ARCH}_000"
    /bin/cp -dR --preserve=timestamps ../files.boot/sys_arm64_000/overlays  "${ROOTFS_DIR}/boot/sys_${TARGET_ARCH}_000/"

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
        /usr/bin/install -m 644 ../files.boot/grub/custom-rootfs_ro.cfg  "${ROOTFS_DIR}/boot/grub/custom.cfg"
    else
        /usr/bin/install -m 644 ../files.boot/grub/custom-rootfs_rw.cfg  "${ROOTFS_DIR}/boot/grub/custom.cfg"
    fi
    /bin/sed -i "s/sys_amd64_000/sys_${TARGET_ARCH}_000/g"   "${ROOTFS_DIR}/boot/grub/custom.cfg"
    /bin/cp "${ROOTFS_DIR}/boot/grub/custom.cfg"             "${ROOTFS_DIR}/boot/sys_${TARGET_ARCH}_000/"
    # Done in stage2 only for 'ROOTFS_RO'
    /bin/sed -i 's/GRUB_DEFAULT=.*$/GRUB_DEFAULT=loop_rootfs/g;s/GRUB_TIMEOUT=.*$/GRUB_TIMEOUT=0/g;s/#GRUB_TERMINAL=.*$/GRUB_TERMINAL=console/g;s/#GRUB_DISABLE_LINUX_UUID=.*$/GRUB_DISABLE_LINUX_UUID=true/g'               "${ROOTFS_DIR}/etc/default/grub"
    echo "GRUB_DISABLE_LINUX_PARTUUID=true"           >> "${ROOTFS_DIR}/etc/default/grub"
    echo "GRUB_DISABLE_RECOVERY=true"                 >> "${ROOTFS_DIR}/etc/default/grub"
    /bin/rm -f                                           "${ROOTFS_DIR}/etc/grub.d/05_debian_theme"
    /bin/rm -f                                           "${ROOTFS_DIR}/etc/grub.d/10_linux"
    /bin/rm -f                                           "${ROOTFS_DIR}/etc/grub.d/20_linux_xen"
    /bin/rm -f                                           "${ROOTFS_DIR}/etc/grub.d/30_os-prober"
    /bin/rm -f                                           "${ROOTFS_DIR}/etc/grub.d/30_uefi-firmware"
    /bin/rm -f                                           "${ROOTFS_DIR}/etc/grub.d/20_memtest86"
    /bin/rm -f                                           "${ROOTFS_DIR}/etc/grub.d/20_memtest86+"
fi

/bin/mkdir -p                                               "${ROOTFS_DIR}/boot/zafena/data"

/bin/cp -dR --preserve=timestamps     ../files.zafena_app/* "${ROOTFS_DIR}/boot/zafena/"

/bin/cat ../files.home/pi/.bashrc_startx                 >> "${ROOTFS_DIR}/home/pi/.bashrc"

echo $CUSTOM_VERSION                                     >  "${ROOTFS_DIR}/etc/zafena_version"
echo $CUSTOM_VERSION                                     >  "${ROOTFS_DIR}/boot/sys_${TARGET_ARCH}_000/zafena_version"

/bin/tar -C ${ROOTFS_DIR} -xzf ../files/zafena-plym-splash.tgz

on_chroot << EOF
    /usr/sbin/plymouth-set-default-theme zafena
    echo "Set plymouth theme: "
    /usr/sbin/plymouth-set-default-theme
EOF

if [ "${TARGET_RASPI}" != "1" ]; then
    # Enable console auto-login, like: 'SUDO_USER="${FIRST_USER_NAME}" raspi-config nonint do_boot_behaviour B2'
    on_chroot << EOF
        systemctl set-default multi-user.target
        ln -fs /lib/systemd/system/getty@.service /etc/systemd/system/getty.target.wants/getty@tty1.service
EOF
    cat > ${ROOTFS_DIR}/etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin ${FIRST_USER_NAME} --noclear %I \$TERM
EOF

    # Also allow user ${FIRST_USER_NAME} to 'sudo' w/o password
    /usr/bin/install -o 0 -g 0 -p -m 440 ../files/sudoers_d-010_pi-nopasswd  "${ROOTFS_DIR}/etc/sudoers.d/010_pi-nopasswd"
fi
# Make sure to allow FIRST_USER_NAME to sudo w/o password, not fixed 'pi'
sed -i "s/pi/${FIRST_USER_NAME}/g"                                           "${ROOTFS_DIR}/etc/sudoers.d/010_pi-nopasswd"

on_chroot << EOF
    dpkg -P nfs-common rpcbind rsync autofs
    apt-get ${APT_GET_INSTALL_OPTS} autoremove -y

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
        # Rebuild /data/sdcard and initrd.img flush stage2 results
        rm -rf /data/sdcard
        rm -f /boot/sys_${TARGET_ARCH}_000/initrd.img

        echo "mkinitramfs for kernel version: \${KVERSION}"
        /usr/sbin/mkinitramfs -o /boot/sys_${TARGET_ARCH}_000/initrd.img \${KVERSION}

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

        # Remove storage device related search.fs_uuid and allow multi homing
        rm -f /boot/grub/i386-pc/load.cfg
    fi
EOF

/bin/chown -R ${fusrname}:${fgrpname} ../files.etc
/bin/chown -R ${fusrname}:${fgrpname} ../files.home
/bin/chown -R ${fusrname}:${fgrpname} ../files.elevator

