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
## stage2/02-net-tweaks
##

on_chroot << EOF
    $(declare -f apt_install)

    apt_install net-tools ifupdown dhcpcd5 avahi-daemon iftop \
                bluez \
                nfs-common autofs openssh-server ssh ssh-import-id rsync curl \
                wpasupplicant wireless-tools firmware-atheros firmware-brcm80211 firmware-libertas firmware-misc-nonfree firmware-realtek \
                rfkill 
EOF

if [ -n "${PUBKEY_SSH_FIRST_USER}" ]; then
	install -v -m 0700 -o 1000 -g 1000 -d "${ROOTFS_DIR}"/home/"${FIRST_USER_NAME}"/.ssh
	echo "${PUBKEY_SSH_FIRST_USER}" >"${ROOTFS_DIR}"/home/"${FIRST_USER_NAME}"/.ssh/authorized_keys
    if [ -n "${PUBKEY2_SSH_FIRST_USER}" ]; then
        echo "${PUBKEY2_SSH_FIRST_USER}" >>"${ROOTFS_DIR}"/home/"${FIRST_USER_NAME}"/.ssh/authorized_keys
    fi
	chown 1000:1000 "${ROOTFS_DIR}"/home/"${FIRST_USER_NAME}"/.ssh/authorized_keys
	chmod 0600 "${ROOTFS_DIR}"/home/"${FIRST_USER_NAME}"/.ssh/authorized_keys
fi

if [ "${PUBKEY_ONLY_SSH}" = "1" ]; then
	sed -i -Ee 's/^#?[[:blank:]]*PubkeyAuthentication[[:blank:]]*no[[:blank:]]*$/PubkeyAuthentication yes/
s/^#?[[:blank:]]*PasswordAuthentication[[:blank:]]*yes[[:blank:]]*$/PasswordAuthentication no/' "${ROOTFS_DIR}"/etc/ssh/sshd_config
fi

install -m 644 files/network/ethN   "${ROOTFS_DIR}/etc/network/interfaces.d/"
install -m 644 files/network/enN    "${ROOTFS_DIR}/etc/network/interfaces.d/"

install -v -d					"${ROOTFS_DIR}/etc/wpa_supplicant"
install -v -m 600 files/wpa_supplicant.conf	"${ROOTFS_DIR}/etc/wpa_supplicant/"

echo "env force_hostname=YES" >> "${ROOTFS_DIR}/etc/dhcpcd.conf"

if [ -v WPA_COUNTRY ]; then
	echo "country=${WPA_COUNTRY}" >> "${ROOTFS_DIR}/etc/wpa_supplicant/wpa_supplicant.conf"
fi

if [ -v WPA_ESSID ] && [ -v WPA_PASSWORD ]; then
    on_chroot <<EOF
        set -o pipefail
        wpa_passphrase "${WPA_ESSID}" "${WPA_PASSWORD}" | tee -a "/etc/wpa_supplicant/wpa_supplicant.conf"
EOF
elif [ -v WPA_ESSID ]; then
        cat >> "${ROOTFS_DIR}/etc/wpa_supplicant/wpa_supplicant.conf" << EOL

        network={
            ssid="${WPA_ESSID}"
            key_mgmt=NONE
        }
EOL
fi

on_chroot << EOF
    $(declare -f apt_install)

    # default off, user may enable ..
    systemctl disable wpa_supplicant
    systemctl mask wpa_supplicant
    systemctl disable rsync
    systemctl mask rsync
    systemctl disable nfs-common
    systemctl mask nfs-common
    systemctl disable rpcbind
    systemctl mask rpcbind

    if [ "${ENABLE_SSH}" == "1" ]; then
        systemctl unmask ssh
        systemctl enable ssh
    else
        systemctl disable ssh
        systemctl mask ssh
    fi
    systemctl mask regenerate_ssh_host_keys
    systemctl disable regenerate_ssh_host_keys

    systemctl unmask systemd-rfkill
    systemctl enable systemd-rfkill
    rfkill block all
EOF

#
# stage2/03-set-timezone
#
echo "${TIMEZONE_DEFAULT}" > "${ROOTFS_DIR}/etc/timezone"
rm "${ROOTFS_DIR}/etc/localtime"

on_chroot << EOF
dpkg-reconfigure -f noninteractive tzdata
EOF

#
# stage2 conclusion
#
sed -i 's/#GRUB_TERMINAL=.*$/GRUB_TERMINAL=console/g' "${ROOTFS_DIR}/etc/default/grub"

on_chroot << EOF
    KVERSION=\$(ls /lib/modules/ | tail -n 1)
    update-initramfs -u -k \${KVERSION}

    grub-install --target=i386-pc --force-file-id /dev/disk/by-id/$DISK1
    grub-install --target=i386-pc --force-file-id /dev/disk/by-id/$DISK2
    grub-install --target=i386-pc --force-file-id /dev/disk/by-id/$DISK3
    update-grub
    mkdir -p /boot/efi/EFI/debian
    grub-install --target=x86_64-efi --removable --force-file-id --efi-directory=/boot/efi --bootloader-id=debian
EOF


#
# Complete Initial Installation
#

on_chroot << EOF
    # SWAP
    zfs create -V $MYSWAPSIZE -b $(getconf PAGESIZE) -o compression=zle \
          -o logbias=throughput -o sync=always \
          -o primarycache=metadata -o secondarycache=none \
          -o com.sun:auto-snapshot=false $POOL/swap

    zfs set compression=zle $POOL/swap
    zfs set logbias=throughput $POOL/swap
    zfs set sync=always $POOL/swap
    zfs set primarycache=metadata $POOL/swap
    zfs set secondarycache=none $POOL/swap
    zfs set com.sun:auto-snapshot=false $POOL/swap
    zfs set checksum=off $POOL/swap

    mkswap -f /dev/zvol/$POOL/swap
    echo /dev/zvol/$POOL/swap none swap defaults 0 0 >> /etc/fstab
    # UUID=ee57ce05-7287-4b37-93c4-03aeaba756f1
    # /etc/fstab
    # /dev/zvol/$POOL/swap   none  		   swap    defaults  0  0
    # 
    swapon /dev/zvol/$POOL/swap

    # logrotate w/o compression (zfs is compressed)
    for f in /etc/logrotate.d/* ; do
      if grep -Eq "(^|[^#y])compress" "\$f" ; then
        sed -i -r "s/(^|[^#y])(compress)/\1#\2/" "\$f"
      fi
    done

    # final update and snapshot
    apt-get update
    apt-get clean

    zfs snapshot $POOL/system/debian@install_s2
EOF

#umount -R /mnt/dev
#umount -R /mnt/proc
#umount -R /mnt/sys
cat /proc/mounts | awk '{print $2}' | grep "${ROOTFS_DIR}" | sort -r | xargs umount

zfs unmount -a
zpool export $POOL

