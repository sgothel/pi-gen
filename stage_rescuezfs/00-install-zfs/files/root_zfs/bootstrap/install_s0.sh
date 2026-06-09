#! /bin/bash -e

##
## Prepare ROOT
##
## zfs root expected to be mounted on ${ROOTFS_DIR}
##

export BASE_DIR=`dirname $(readlink -f "${BASH_SOURCE[0]}")`
export PROJECT_DIR=`readlink -f ..`
export PROJECT_NAME=`basename ${PROJECT_DIR}`

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
## (ensure same kernel version as host)
##
export KVERSION_HOST=$(ls /lib/modules/ | tail -n 1)

on_chroot << EOF
    $(declare -f apt_install)

    # locales with pre-selection
    debconf-set-selections <<SELEOF
        $(cat "files/locale-debconf")
SELEOF
    apt_install locales

    # firmware and kernel
    apt_install gdisk build-essential dkms dpkg-dev linux-headers-${TARGET_ARCH} linux-image-${TARGET_ARCH} \
                linux-headers-${KVERSION_HOST} linux-image-${KVERSION_HOST} \
                atmel-firmware firmware-amd-graphics firmware-bnx2 firmware-bnx2x \
                firmware-brcm80211 \
                firmware-iwlwifi firmware-libertas firmware-linux firmware-linux-free firmware-linux-nonfree \
                firmware-misc-nonfree firmware-myricom firmware-netxen firmware-qlogic firmware-realtek \
                bluez-firmware
EOF

##
## stage0 ZFS package
##


cp -a ${PROJECT_DIR} "${ROOTFS_DIR}/root/zfs"

on_chroot << EOF
    # Build ZFS from scratch requirements
    apt_install sysfsutils grub-pc-bin efibootmgr grub-efi-amd64 grub-efi-amd64-bin grub-efi-amd64-signed \
                linux-headers-generic libselinux-dev gdisk parted lsscsi wget ksh gdebi

    apt_install alien autoconf automake build-essential debhelper-compat dh-autoreconf dh-dkms dh-python dkms fakeroot gawk \
                git libaio-dev libattr1-dev libblkid-dev libcurl4-openssl-dev libelf-dev libffi-dev libpam0g-dev libssl-dev libtirpc-dev \
                libtool libudev-dev linux-headers-generic parallel po-debconf \
                python3 python3-all-dev python3-cffi python3-dev python3-packaging python3-setuptools python3-sphinx \
                uuid-dev zlib1g-dev libunwind-dev python3-distutils-extra

    # Replace Debian ZFS packages and replace with vanilla latest release
    cd /root/zfs
    . ./scripts/zfs-remove.sh
    if [ "${RELEASE}" = "trixie" ]; then
        . ./scripts/zfs-install-debian13-${TARGET_ARCH}.sh
    elif [ "${RELEASE}" = "bookworm" ]; then
        . ./scripts/zfs-install-debian12-${TARGET_ARCH}.sh
    else
        echo "No ZFS packages provisioned for RELEASE ${RELEASE}"
        exit 2
    fi

    cat ./bootstrap/files/apt-preferences.d-local-pin-init >> /etc/apt/preferences.d/local-pin-init

    systemctl enable zfs-import-cache.service zfs-mount.service zfs-zed.service zfs-import.target zfs-volumes.target zfs.target
    systemctl start zfs-import-cache.service zfs-mount.service zfs-zed.service zfs-import.target zfs-volumes.target zfs.target

    zfs snapshot $POOL/system/debian@install_s0
EOF

