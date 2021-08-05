#!/bin/bash -e

if [ "${TARGET_RASPI}" = "1" -a "${TARGET_ARCH}" = "armhf" ]; then
    install -m 644 files/sources-raspi_armhf.list "${ROOTFS_DIR}/etc/apt/sources.list"
elif [ "${IS_TESTING}" = "1" ]; then
    install -m 644 files/sources-testing.list "${ROOTFS_DIR}/etc/apt/sources.list"
else
    install -m 644 files/sources-stable.list "${ROOTFS_DIR}/etc/apt/sources.list"
fi
sed -i "s/RELEASE/${RELEASE}/g" "${ROOTFS_DIR}/etc/apt/sources.list"

if [ "${TARGET_RASPI}" = "1" ]; then
    install -m 644 files/raspi.list "${ROOTFS_DIR}/etc/apt/sources.list.d/"
    sed -i "s/RELEASE/${RELEASE}/g" "${ROOTFS_DIR}/etc/apt/sources.list.d/raspi.list"
fi

if [ -n "$APT_PROXY" ]; then
	install -m 644 files/51cache "${ROOTFS_DIR}/etc/apt/apt.conf.d/51cache"
	sed "${ROOTFS_DIR}/etc/apt/apt.conf.d/51cache" -i -e "s|APT_PROXY|${APT_PROXY}|"
else
	rm -f "${ROOTFS_DIR}/etc/apt/apt.conf.d/51cache"
fi

if [ "${TARGET_RASPI}" = "1" ]; then
    on_chroot apt-key add - < files/raspberrypi.gpg.key
fi

# Disable apt caching in general
install -m 644 files/02nocache "${ROOTFS_DIR}/etc/apt/apt.conf.d/02nocache"

if [ "${INSTALL_RECOMMENDS}" != "1" -o "${REDUCED_FOOTPRINT}" = "1" ]; then
    # Drop recommended packages if using reduced footprint or not explicitly selected
    install -m 644 files/00default-selection "${ROOTFS_DIR}/etc/apt/apt.conf.d/00default-selection"
fi

if [ "${REDUCED_FOOTPRINT}" = "1" ]; then
    install -m 644 files/01_nodoc            "${ROOTFS_DIR}/etc/dpkg/dpkg.cfg.d/01_nodoc"
fi

on_chroot << EOF
if [ "${TARGET_ARCH}" = "arm64" ]; then
    dpkg --add-architecture armhf
fi
apt-get update
apt-get dist-upgrade -y
EOF

