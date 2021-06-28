#!/bin/bash -e

IMG_FILE="${STAGE_WORK_DIR}/${IMG_FILENAME}${IMG_SUFFIX}.img"
INFO_FILE="${STAGE_WORK_DIR}/${IMG_FILENAME}${IMG_SUFFIX}.info"

IMG_FILE_ROOT="${STAGE_WORK_DIR}/${IMG_FILENAME}${IMG_SUFFIX}.root.img"
INFO_FILE_ROOT="${STAGE_WORK_DIR}/${IMG_FILENAME}${IMG_SUFFIX}.root.info"
#IMG_FILE_BOOT="${STAGE_WORK_DIR}/${IMG_FILENAME}${IMG_SUFFIX}.boot.img"
#INFO_FILE_BOOT="${STAGE_WORK_DIR}/${IMG_FILENAME}${IMG_SUFFIX}.boot.info"
#IMG_FILE_DATA="${STAGE_WORK_DIR}/${IMG_FILENAME}${IMG_SUFFIX}.data.img"
#INFO_FILE_DATA="${STAGE_WORK_DIR}/${IMG_FILENAME}${IMG_SUFFIX}.data.info"

on_chroot << EOF
if [ -x /etc/init.d/fake-hwclock ]; then
	/etc/init.d/fake-hwclock stop
fi
if hash hardlink 2>/dev/null; then
	hardlink -t /usr/share/doc
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
#cp "$INFO_FILE" "$INFO_FILE_BOOT"
#cp "$INFO_FILE" "$INFO_FILE_DATA"

echo >> "$INFO_FILE_ROOT"
echo "+++" >> "$INFO_FILE_ROOT"
echo >> "$INFO_FILE_ROOT"
echo "Root Partition `basename $IMG_FILE_ROOT`" >> "$INFO_FILE_ROOT"
echo "Root Partition of `basename $IMG_FILE`" >> "$INFO_FILE_ROOT"
echo >> "$INFO_FILE_ROOT"

#echo >> "$INFO_FILE_BOOT"
#echo "+++" >> "$INFO_FILE_BOOT"
#echo >> "$INFO_FILE_BOOT"
#echo "Boot Partition `basename $IMG_FILE_BOOT`" >> "$INFO_FILE_BOOT"
#echo "Boot Partition of `basename $IMG_FILE`" >> "$INFO_FILE_BOOT"
#echo >> "$INFO_FILE_BOOT"

#echo >> "$INFO_FILE_DATA"
#echo "+++" >> "$INFO_FILE_DATA"
#echo >> "$INFO_FILE_DATA"
#echo "Data Partition `basename $IMG_FILE_DATA`" >> "$INFO_FILE_DATA"
#echo "Data Partition of `basename $IMG_FILE`" >> "$INFO_FILE_DATA"
#echo >> "$INFO_FILE_DATA"

mkdir -p "${DEPLOY_DIR}"

rm -f "${DEPLOY_DIR}/${IMG_FILENAME}${IMG_SUFFIX}.{img,img.gz,.info}"
rm -f "${DEPLOY_DIR}/${IMG_FILENAME}${IMG_SUFFIX}.root.{img,img.gz,.info}"
rm -f "${DEPLOY_DIR}/${IMG_FILENAME}${IMG_SUFFIX}.boot.{img,img.gz,.info}"
rm -f "${DEPLOY_DIR}/${IMG_FILENAME}${IMG_SUFFIX}.data.{img,img.gz,.info}"

if [ "${USE_QCOW2}" = "0" ] && [ "${NO_PRERUN_QCOW2}" = "0" ]; then
	ROOT_DEV="$(mount | grep "${ROOTFS_DIR} " | cut -f1 -d' ')"

	unmount "${ROOTFS_DIR}"
	zerofree "${ROOT_DEV}"

	unmount_image "${IMG_FILE}"
else
	unload_qimage
	make_bootable_image "${STAGE_WORK_DIR}/${IMG_FILENAME}${IMG_SUFFIX}.qcow2" \
        "$IMG_FILE" \
        "$IMG_FILE_ROOT" "$INFO_FILE_ROOT"

#        "$IMG_FILE_BOOT" "$INFO_FILE_BOOT" \
#        "$IMG_FILE_DATA" "$INFO_FILE_DATA"

fi

mv "$INFO_FILE" "$INFO_FILE_ROOT" "$DEPLOY_DIR/"
#mv "$INFO_FILE" "$INFO_FILE_ROOT" "$INFO_FILE_BOOT" "$INFO_FILE_DATA" "$DEPLOY_DIR/"

if [ "${DEPLOY_ZIP}" == "1" ]; then
	gzip -k "$IMG_FILE"
	gzip -k "$IMG_FILE_ROOT"
	#gzip -k "$IMG_FILE_BOOT"
	#gzip -k "$IMG_FILE_DATA"
    mv "$IMG_FILE".gz      "$DEPLOY_DIR/"
    mv "$IMG_FILE_ROOT".gz "$DEPLOY_DIR/"
    #mv "$IMG_FILE_BOOT".gz "$DEPLOY_DIR/"
    #mv "$IMG_FILE_DATA".gz "$DEPLOY_DIR/"
fi

mv "$IMG_FILE"      "$DEPLOY_DIR/"
mv "$IMG_FILE_ROOT" "$DEPLOY_DIR/"
#mv "$IMG_FILE_BOOT" "$DEPLOY_DIR/"
#mv "$IMG_FILE_DATA" "$DEPLOY_DIR/"
