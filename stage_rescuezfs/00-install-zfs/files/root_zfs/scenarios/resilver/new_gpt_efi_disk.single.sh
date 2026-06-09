#!/bin/sh

NDISK1=ata-QEMU_HARDDISK_QM00007

# EF02 Bios-Boot (Grub core)
# EF00 EFI System
# BF01 ZFS Root
for dname in "${NDISK1}" ; do
    sgdisk --zap-all \
      --new 1::+1M   --typecode=1:EF02 \
      --new 2::+700M --typecode=2:EF00 \
      --new 3::0     --typecode=3:BF01 \
      "/dev/disk/by-id/${dname}"
done

sleep 3
sync

# Create EFI filesystems
mkfs.fat -n EFISYS -F32 /dev/disk/by-id/$NDISK1-part2

echo "Now replace the disk .."
echo "zpool replace POOL removed-disc-id /dev/disk/by-id/${NDISK1}-part3"
