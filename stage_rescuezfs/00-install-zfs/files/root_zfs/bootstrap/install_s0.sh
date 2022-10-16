#! /bin/bash -e

##
## Prepare ROOT
##
## zfs root expected to be mounted on ${ROOTFS_DIR}
##

export BASE_DIR=`dirname $(readlink -f "${BASH_SOURCE[0]}")`

source "${BASE_DIR}/install.cfg"

source "${BASE_DIR}/common.sh"

if [ "${TARGET_ARCH}" != "amd64" ]; then
    echo "ZFS install not supported on ARCH ${TARGET_ARCH}, only on amd64"
    exit 2
fi

##
## copy our zfs compatibility settings
##

mkdir -p "${ROOTFS_DIR}/etc/zfs"
cp -a /etc/zfs/compatibility.d "${ROOTFS_DIR}/etc/zfs/"

##
## stage0 bootstrap and initial setup
##

bootstrap ${RELEASE} "${ROOTFS_DIR}" ${DEB_SERVER}

if [ "${IS_TESTING}" = "1" ]; then
    install -m 644 files/sources-testing.list "${ROOTFS_DIR}/etc/apt/sources.list"
else
    install -m 644 files/sources-stable.list "${ROOTFS_DIR}/etc/apt/sources.list"
fi
sed -i -e "s@RELEASE@${RELEASE}@g" -e "s@DEB_SERVER@${DEB_SERVER}@g" "${ROOTFS_DIR}/etc/apt/sources.list"

if [ -n "$APT_PROXY" ]; then
	install -m 644 files/51cache "${ROOTFS_DIR}/etc/apt/apt.conf.d/51cache"
	sed "${ROOTFS_DIR}/etc/apt/apt.conf.d/51cache" -i -e "s|APT_PROXY|${APT_PROXY}|"
else
	rm -f "${ROOTFS_DIR}/etc/apt/apt.conf.d/51cache"
fi

on_chroot << EOF
    if [ "${TARGET_ARCH}" = "arm64" ]; then
        dpkg --add-architecture armhf
    fi
    apt-get update
    apt-get dist-upgrade -y
EOF

##
## stage0 setup locales and install kernel/firmware
##

on_chroot << EOF
    $(declare -f apt_install)

    # locales with pre-selection
    debconf-set-selections <<SELEOF
        $(cat "files/locale-debconf")
SELEOF
    apt_install locales

    # firmware and kernel
    apt_install gdisk build-essential dkms dpkg-dev linux-headers-${TARGET_ARCH} linux-image-${TARGET_ARCH} \
                amd64-microcode intel-microcode \
                atmel-firmware firmware-amd-graphics firmware-bnx2 firmware-bnx2x \
                firmware-brcm80211 firmware-intelwimax  \
                firmware-iwlwifi firmware-libertas firmware-linux firmware-linux-free firmware-linux-nonfree \
                firmware-misc-nonfree firmware-myricom firmware-netxen firmware-qlogic firmware-realtek \
                bluez-firmware
EOF

##
## stage0 ZFS package
##

cp -a ${BASE_DIR}/../../zfs "${ROOTFS_DIR}/root/"

on_chroot << EOF
    # Build ZFS from scratch requirements
    apt_install sysfsutils grub-pc \
                build-essential autoconf automake libtool gawk alien fakeroot dkms libblkid-dev uuid-dev libudev-dev \
                libssl-dev zlib1g-dev libaio-dev libattr1-dev libelf-dev \
                linux-headers-generic \
                python3 python3-dev python3-setuptools python3-cffi libffi-dev python3-packaging git libcurl4-openssl-dev \
                linux-headers-amd64 libselinux-dev \
                parted lsscsi wget ksh gdebi python3-distutils

    # Replace Debian ZFS packages and replace with vanilla latest release
    cd /root/zfs
    . ./zfs-remove.sh
    if [ "${RELEASE}" = "bookworm" ]; then
        . ./zfs-install-debian12-${TARGET_ARCH}.sh
    elif [ "${RELEASE}" = "bullseye" ]; then
        . ./zfs-install-debian11-${TARGET_ARCH}.sh
    elif [ "${RELEASE}" = "buster" ]; then
        . ./zfs-install-debian10-${TARGET_ARCH}.sh
    else
        echo "No ZFS packages provisioned for RELEASE ${RELEASE}"
        exit 2
    fi

    cat ./apt-preferences.d-local-pin-init >> /etc/apt/preferences.d/local-pin-init

    systemctl enable zfs-import-cache.service zfs-mount.service zfs-zed.service zfs-import.target zfs-volumes.target zfs.target
    systemctl start zfs-import-cache.service zfs-mount.service zfs-zed.service zfs-import.target zfs-volumes.target zfs.target

    zfs snapshot $POOL/system/debian@install_s0
EOF

