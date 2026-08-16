#!/bin/sh

# sda .. 
DISKS="ata-QEMU_HARDDISK_QM00001"
DISKS="$DISKS ata-QEMU_HARDDISK_QM00002"
DISKS="$DISKS ata-QEMU_HARDDISK_QM00003"

for i in $DISKS ; do
    echo
    echo $i
    smartctl -x /dev/disk/by-id/$i > smart-$i.txt
    #smartctl -t offline /dev/disk/by-id/$i
done

