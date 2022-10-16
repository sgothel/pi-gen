#! /bin/sh
#

#
# Perform zfs auto import w/ temp root on /mnt
#
# - without force: zfs import -a -R /mnt
# - with force: zfs import -a -f -R /mnt
#

# bind the special devices and pipes to zfs realm
#
mount --bind /dev/  /mnt/dev/
mount --bind /sys/  /mnt/sys/
mount --bind /proc/ /mnt/proc/

# chroot into it
#
# chroot /mnt
#

# Potentially you might need to 
# 
# - update-initramfs -u -k all
# - update-grub
# - grub-install /dev/disk/by-id/your_boot_root_device
#
