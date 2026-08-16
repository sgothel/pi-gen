#!/bin/sh

# sda .. sdf + nvme
DISKS="ata-WDC_WD80EFPX-68C4ZN0_WD-SN1"
DISKS="$DISKS ata-WDC_WD80EFPX-68C4ZN0_WD-SN2"
DISKS="$DISKS ata-WDC_WD80EFPX-68C4ZN0_WD-SN3"
DISKS="$DISKS ata-WDC_WD80EFPX-68C4ZN0_WD-SN4"
DISKS="$DISKS ata-WDC_WD80EFPX-68C4ZN0_WD-SN5"
DISKS="$DISKS ata-WDC_WD80EFPX-68C4ZN0_WD-SN6"
DISKS="$DISKS nvme-Samsung_SSD_970_EVO_Plus_1TB_SN7"

for i in $DISKS ; do
    echo
    echo $i
    grub-install --target=i386-pc --force-file-id /dev/disk/by-id/$i
done

update-grub
mkdir -p /boot/efi/EFI/debian
grub-install --target=x86_64-efi --removable --force-file-id --efi-directory=/boot/efi --bootloader-id=debian
