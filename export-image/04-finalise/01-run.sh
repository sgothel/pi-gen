#!/bin/bash -e

if [ -z "${DEPLOY_DIR}" ] ; then
    echo "Error: Empty DEPLOY_DIR"
    exit 1
elif [ "${DEPLOY_DIR}" = "/" ] ; then
    echo "Error: DEPLOY_DIR is root"
    exit 1
fi

DEPLOY_DIR2="${DEPLOY_DIR}/${IMG_FILENAME}"

IMG_FILE="${STAGE_WORK_DIR}/${IMG_FILENAME}${IMG_SUFFIX}.img"
INFO_FILE="${STAGE_WORK_DIR}/${IMG_FILENAME}${IMG_SUFFIX}.info"

IMG_FILE_ROOT_EXT4="${STAGE_WORK_DIR}/${IMG_FILENAME}${IMG_SUFFIX}.root-ext4.img"
IMG_FILE_ROOT_SQFS_GZ="${STAGE_WORK_DIR}/${IMG_FILENAME}${IMG_SUFFIX}.root-sqfs_gz.img"
IMG_FILE_ROOT_SQFS_LZO="${STAGE_WORK_DIR}/${IMG_FILENAME}${IMG_SUFFIX}.root-sqfs_lzo.img"
IMG_FILE_ROOT_SQFS_NONE="${STAGE_WORK_DIR}/${IMG_FILENAME}${IMG_SUFFIX}.root-sqfs_none.img"
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

if [ "${ROOTFS_RO}" = "1" ] ; then
    cp "$INFO_FILE" "$INFO_FILE_ROOT"
    echo >> "$INFO_FILE_ROOT"
    echo "+++" >> "$INFO_FILE_ROOT"
    echo >> "$INFO_FILE_ROOT"
    echo "Root Partition `basename $IMG_FILE_ROOT_EXT4`" >> "$INFO_FILE_ROOT"
    echo "Root Partition of `basename $IMG_FILE`" >> "$INFO_FILE_ROOT"
    echo >> "$INFO_FILE_ROOT"
fi

rm -rf "${DEPLOY_DIR2}"
mkdir -p "${DEPLOY_DIR2}"

if [ "${ROOTFS_RO}" = "1" ] ; then
    cp -a "${ROOTFS_DIR}/boot" "${DEPLOY_DIR2}/sdcard${IMG_SUFFIX}"
fi

unload_qimage
make_bootable_image "${STAGE_WORK_DIR}/${IMG_FILENAME}${IMG_SUFFIX}.qcow2" \
    "$IMG_FILE" \
    "$IMG_FILE_ROOT_EXT4" "$INFO_FILE_ROOT"

if [ "${ROOTFS_RO}" = "1" ] ; then
    mount -o ro "$IMG_FILE_ROOT_EXT4" "${ROOTFS_DIR}"
    mksquashfs "${ROOTFS_DIR}" "${IMG_FILE_ROOT_SQFS_GZ}" -comp gzip
    mksquashfs "${ROOTFS_DIR}" "${IMG_FILE_ROOT_SQFS_LZO}" -comp lzo
    mksquashfs "${ROOTFS_DIR}" "${IMG_FILE_ROOT_SQFS_NONE}" -noI -noD -noF -noX
    umount "${ROOTFS_DIR}"
    cp -a "$INFO_FILE_ROOT" "${DEPLOY_DIR2}/sdcard${IMG_SUFFIX}/sys_arm64_000/rootfs.inf"
fi
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
    # cp -a "$IMG_FILE_ROOT_EXT4" "${DEPLOY_DIR2}/sdcard${IMG_SUFFIX}/sys_arm64_000/rootfs.img"
    cp -a "$IMG_FILE_ROOT_SQFS_LZO" "${DEPLOY_DIR2}/sdcard${IMG_SUFFIX}/sys_arm64_000/rootfs.img"

    mv "$IMG_FILE_ROOT_EXT4" "$DEPLOY_DIR2/"
    mv "$IMG_FILE_ROOT_SQFS_GZ" "$DEPLOY_DIR2/"
    mv "$IMG_FILE_ROOT_SQFS_LZO" "$DEPLOY_DIR2/"
    mv "$IMG_FILE_ROOT_SQFS_NONE" "$DEPLOY_DIR2/"
fi
