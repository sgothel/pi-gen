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
## stage1
##

# fstab and user
install -v -m 644 files/fstab "${ROOTFS_DIR}/etc/fstab"

on_chroot << EOF
    if ! id -u ${FIRST_USER_NAME} >/dev/null 2>&1; then
        adduser --disabled-password --gecos "" ${FIRST_USER_NAME}
    fi
    echo "${FIRST_USER_NAME}:${FIRST_USER_PASS}" | chpasswd
    echo "root:root" | chpasswd
EOF

# stage1 TCP/IP basic networking
on_chroot << EOF
    $(declare -f apt_install)

    apt_install netbase ethtool
EOF
echo "${TARGET_HOSTNAME}" > "${ROOTFS_DIR}/etc/hostname"
echo "127.0.1.1		${TARGET_HOSTNAME}" >> "${ROOTFS_DIR}/etc/hosts"

ln -sf /dev/null "${ROOTFS_DIR}/etc/systemd/network/99-default.link"

# stage1 essential packages
on_chroot << EOF
    $(declare -f apt_install)

    debconf-set-selections <<SELEOF
        $(cat "files/console-debconf")
SELEOF

    # Fundamentals
    apt_install less sysfsutils grub-pc-bin efibootmgr grub-efi-amd64 grub-efi-amd64-bin grub-efi-amd64-signed \
                vim sharutils psmisc htop patch fbset sudo \
                console-setup keyboard-configuration debconf-utils parted unzip bash-completion \
                manpages-dev gdb pkg-config libstdc++6 python3-minimal strace \
                v4l-utils lua5.1 luajit hardlink ca-certificates \
                usbutils libfreetype6-dev dosfstools squashfs-tools fatattr \
                lzop apt-listchanges usb-modeswitch libmtp-runtime htop iotop powertop \
                man-db policykit-1 rng-tools ntfs-3g pciutils busybox initramfs-tools-core initramfs-tools

    # debootstrap requirements (pi-gen requirements on target for reproduction)
    apt_install coreutils quilt parted qemu-user-static debootstrap zerofree zip dosfstools libarchive-tools libcap2-bin grep \
                xz-utils file git curl bc qemu-utils kpartx squashfs-tools fatattr

    # ensure sysfsutils is enabled at boot
    systemctl is-enabled sysfsutils

    for GRP in input spi i2c gpio; do
        groupadd -f -r "\$GRP"
    done
    for GRP in adm dialout cdrom audio users sudo video games plugdev input gpio spi i2c netdev; do
      adduser $FIRST_USER_NAME \$GRP
    done

    setupcon --force --save-only -v
    usermod --pass='*' root

    zfs snapshot $POOL/system/debian@install_s1
EOF

