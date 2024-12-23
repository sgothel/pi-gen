#!/bin/bash -e

if [ -z "${DEPLOY_DIR}" ] ; then
    echo "Error: Empty DEPLOY_DIR"
    exit 1
elif [ "${DEPLOY_DIR}" = "/" ] ; then
    echo "Error: DEPLOY_DIR is root"
    exit 1
fi

DEPLOY_DIR2="${DEPLOY_DIR}/${IMG_FILENAME}"

QCOW2_FILE="${STAGE_WORK_DIR}/${IMG_FILENAME}${IMG_SUFFIX}.qcow2"
IMG_FILE="${STAGE_WORK_DIR}/${IMG_FILENAME}${IMG_SUFFIX}.img"
INFO_FILE="${STAGE_WORK_DIR}/${IMG_FILENAME}${IMG_SUFFIX}.info"

IMG_FILE_ROOT_EXT4="${STAGE_WORK_DIR}/${IMG_FILENAME}${IMG_SUFFIX}.root-ext4.img"
#IMG_FILE_ROOT_SQFS_GZ="${STAGE_WORK_DIR}/${IMG_FILENAME}${IMG_SUFFIX}.root-sqfs_gz.img"
IMG_FILE_ROOT_SQFS_LZO="${STAGE_WORK_DIR}/${IMG_FILENAME}${IMG_SUFFIX}.root-sqfs_lzo.img"
#IMG_FILE_ROOT_SQFS_ZSTD="${STAGE_WORK_DIR}/${IMG_FILENAME}${IMG_SUFFIX}.root-sqfs_zstd10.img"
INFO_FILE_ROOT="${STAGE_WORK_DIR}/${IMG_FILENAME}${IMG_SUFFIX}.root.info"

on_chroot << EOF
    if [ -x /etc/init.d/fake-hwclock ]; then
        /etc/init.d/fake-hwclock stop
    fi
    if hash hardlink 2>/dev/null; then
        hardlink -t /usr/share/doc
    fi

    if [ "${REDUCED_FOOTPRINT}" = "1" ]; then
        # Keep in sync:
        #  stage0/00-configure-apt/files/01_nodoc 
        #  export-image/04-finalise/01-run.sh 
        find /usr/share/doc -depth -type f ! -name copyright|xargs rm || true
        find /usr/share/doc -empty|xargs rmdir || true
        rm -rf /usr/share/man /usr/share/groff /usr/share/info /usr/share/lintian /usr/share/linda /var/cache/man
        find /usr/share/locale -mindepth 1 -maxdepth 1 ! -name 'en*' ! -name 'da*' ! -name 'de*' ! -name 'es*' ! -name 'fi*' ! -name 'fr*' ! -name 'is*' ! -name 'nb*' ! -name 'ru*' !  -name 'sv*' ! -name 'zh*' |xargs rm -r
    fi
EOF

if [ -d "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.config" ]; then
	chmod 700 "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.config"
fi

rm -f "${ROOTFS_DIR}/usr/bin/qemu-arm-static"

if [ "${USE_QEMU}" != "1" ]; then
	if [ -e "${ROOTFS_DIR}/etc/ld.so.preload.disabled" ]; then
		mv "${ROOTFS_DIR}/etc/ld.so.preload.disabled" "${ROOTFS_DIR}/etc/ld.so.preload"
	fi
fi

rm -f "${ROOTFS_DIR}/etc/network/interfaces.dpkg-old"

rm -f "${ROOTFS_DIR}/etc/apt/sources.list~"
rm -f "${ROOTFS_DIR}/etc/apt/trusted.gpg~"

rm -f "${ROOTFS_DIR}/etc/passwd-"
rm -f "${ROOTFS_DIR}/etc/group-"
rm -f "${ROOTFS_DIR}/etc/shadow-"
rm -f "${ROOTFS_DIR}/etc/gshadow-"
rm -f "${ROOTFS_DIR}/etc/subuid-"
rm -f "${ROOTFS_DIR}/etc/subgid-"

rm -f "${ROOTFS_DIR}"/var/cache/debconf/*-old
rm -f "${ROOTFS_DIR}"/var/lib/dpkg/*-old

rm -f "${ROOTFS_DIR}"/usr/share/icons/*/icon-theme.cache

rm -f "${ROOTFS_DIR}/var/lib/dbus/machine-id"

true > "${ROOTFS_DIR}/etc/machine-id"

ln -nsf /proc/mounts "${ROOTFS_DIR}/etc/mtab"

find "${ROOTFS_DIR}/var/log/" -type f -exec cp /dev/null {} \;

rm -f "${ROOTFS_DIR}/root/.vnc/private.key"
rm -f "${ROOTFS_DIR}/etc/vnc/updateid"

print_issue "$(basename "${EXPORT_DIR}")" > "${ROOTFS_DIR}/etc/rpi-issue"
install -m 644 "${ROOTFS_DIR}/etc/rpi-issue" "${ROOTFS_DIR}/boot/issue.txt"

cp "$ROOTFS_DIR/etc/rpi-issue" "$INFO_FILE"

cp "$INFO_FILE" "$INFO_FILE_ROOT"
echo >> "$INFO_FILE_ROOT"
echo "+++" >> "$INFO_FILE_ROOT"
echo >> "$INFO_FILE_ROOT"
echo "Root Partition `basename $IMG_FILE_ROOT_EXT4`" >> "$INFO_FILE_ROOT"
echo "Root Partition of `basename $IMG_FILE`" >> "$INFO_FILE_ROOT"
echo >> "$INFO_FILE_ROOT"

rm -rf "${DEPLOY_DIR2}"
mkdir -p "${DEPLOY_DIR2}"

if [ "${ROOTFS_RO}" = "1" ] ; then
    cp -a "${ROOTFS_DIR}/boot" "${DEPLOY_DIR2}/sdcard${IMG_SUFFIX}"
fi

if [ "${ROOTFS_RO}" = "1" ] ; then
    finalize_fstab_ro "${ROOTFS_DIR}"
fi

on_chroot <<EOF
    if [ "${TARGET_RASPI}" != "1" ]; then
        # BIOS Boot
        echo "GRUB Install: BIOS: ROOTFS_RO=${ROOTFS_RO}"
        if [ "${ROOTFS_RO}" = "1" ] ; then
            # using manually copied /boot/grub/grub.cfg
            grub-install --target=i386-pc --force-file-id --modules="gzio part_msdos part_gpt fat" /dev/${NBD_DEV}
        else
            grub-install --target=i386-pc --force-file-id --modules="gzio part_msdos part_gpt fat ext2 xfs" /dev/${NBD_DEV}
            update-grub
        fi
        if [ -n "${UEFI_ARCH}" ] ; then
            # EFI Boot
            echo "GRUB Install: UEFI: Using grub-install. ROOTFS_RO=${ROOTFS_RO}"
            mkdir -p /boot/efi/EFI/BOOT
            # --removable: EFI/BOOT/bootx64.efi
            # --uefi-secure-boot (we disable this option)
            grub-install --target=${UEFI_ARCH}-efi --removable --force-file-id --efi-directory=/boot/efi --bootloader-id=BOOT
        fi
        # Remove storage device related search.fs_uuid and allow multi homing
        rm -f /boot/grub/i386-pc/load.cfg
        if [ -n "${UEFI_ARCH}" ] ; then
            rm -f /boot/grub/${UEFI_ARCH}-efi/load.cfg
        fi
    fi
EOF

unload_qimage

if [ "${ROOTFS_RO}" = "1" ] ; then
    rm -f "${IMG_FILE_ROOT_SQFS_LZO}"
    #mksquashfs "${ROOTFS_DIR}" "${IMG_FILE_ROOT_SQFS_GZ}" -comp gzip -no-xattrs
    mksquashfs "${ROOTFS_DIR}" "${IMG_FILE_ROOT_SQFS_LZO}" -comp lzo -no-xattrs
    #mksquashfs "${ROOTFS_DIR}" "${IMG_FILE_ROOT_SQFS_ZSTD}" -comp zstd -Xcompression-level 10 -no-xattrs
    cp -a "$INFO_FILE_ROOT" "${DEPLOY_DIR2}/sdcard${IMG_SUFFIX}/sys_${TARGET_ARCH}_000/rootfs.inf"

    # cp -a "$IMG_FILE_ROOT_EXT4" "${DEPLOY_DIR2}/sdcard${IMG_SUFFIX}/sys_${TARGET_ARCH}_000/rootfs.img"
    cp -a "$IMG_FILE_ROOT_SQFS_LZO" "${DEPLOY_DIR2}/sdcard${IMG_SUFFIX}/sys_${TARGET_ARCH}_000/rootfs.img"
    # cp -a "$IMG_FILE_ROOT_SQFS_ZSTD" "${DEPLOY_DIR2}/sdcard${IMG_SUFFIX}/sys_${TARGET_ARCH}_000/rootfs.img"

	echo "Mount image ${QCOW2_FILE}"
	MOUNTROOT=${STAGE_WORK_DIR}/tmpimage
	mkdir -p $MOUNTROOT
    mount_qimage "${QCOW2_FILE}" "${MOUNTROOT}"
	if [ ! -d "${MOUNTROOT}/boot" ]; then
		echo "Image damaged or not mounted. Exit."
		exit 1
	fi
    cp "$IMG_FILE_ROOT_SQFS_LZO" "${MOUNTROOT}/boot/sys_${TARGET_ARCH}_000/rootfs.img"
	echo "Umount image ${QCOW2_FILE}"
	sync
    umount_image $MOUNTROOT
fi

make_bootable_image "${QCOW2_FILE}" \
    "$IMG_FILE" \
    "$IMG_FILE_ROOT_EXT4" "$INFO_FILE_ROOT"

mv "$INFO_FILE" "$INFO_FILE_ROOT" "$DEPLOY_DIR2/"

if [ "${DEPLOY_ZIP}" == "1" ]; then
	gzip -k "$IMG_FILE"
    mv "$IMG_FILE".gz "$DEPLOY_DIR2/"
    if [ "${ROOTFS_RO}" = "1" ] ; then
        gzip -k "$IMG_FILE_ROOT_EXT4"
        mv "$IMG_FILE_ROOT_EXT4".gz "$DEPLOY_DIR2/"
    fi
fi

mv "$IMG_FILE" "$DEPLOY_DIR2/"

if [ "${ROOTFS_RO}" = "1" ] ; then
    # for now, not zipping the sdcard folder, as we further postprocess it
    # ( cd "${DEPLOY_DIR2}/sdcard${IMG_SUFFIX}"; zip -r0 "../${IMG_FILENAME}${IMG_SUFFIX}.sdcard.zip" . )

    echo "${DEPLOY_DIR2}/sdcard${IMG_SUFFIX} done."

    #mv -v "$IMG_FILE_ROOT_SQFS_GZ" "$DEPLOY_DIR2/"
    mv -v "$IMG_FILE_ROOT_SQFS_LZO" "$DEPLOY_DIR2/"
    #mv -v "$IMG_FILE_ROOT_SQFS_ZSTD" "$DEPLOY_DIR2/"
else
    mv -v "$IMG_FILE_ROOT_EXT4" "$DEPLOY_DIR2/"
fi

rm -f "${STAGE_WORK_DIR}/SHA256SUMS"
( cd "${DEPLOY_DIR2}"; find . -maxdepth 1 -type f -exec sha256sum -b \{\} >> "${STAGE_WORK_DIR}/SHA256SUMS" \; )
mv "${STAGE_WORK_DIR}/SHA256SUMS" "$DEPLOY_DIR2/"

