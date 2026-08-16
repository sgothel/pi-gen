#! /bin/sh

POOLNAME=tpool

DISKS="ata-WDC_WD80EFPX-68C4ZN0_WD-SN1"
DISKS="$DISKS ata-WDC_WD80EFPX-68C4ZN0_WD-SN2"
DISKS="$DISKS ata-WDC_WD80EFPX-68C4ZN0_WD-SN3"
DISKS="$DISKS ata-WDC_WD80EFPX-68C4ZN0_WD-SN4"
DISKS="$DISKS ata-WDC_WD80EFPX-68C4ZN0_WD-SN5"
DISKS="$DISKS ata-WDC_WD80EFPX-68C4ZN0_WD-SN6"
DISKS="$DISKS nvme-Samsung_SSD_970_EVO_Plus_1TB_SN7"

zdb -C ${POOLNAME} > zpool_${POOLNAME}.zdb_C.txt

for i in $DISKS ; do
    zdb -l /dev/disk/by-id/$i > zpool_${POOLNAME}.zdb_l.$i.txt
done

grep pool_guid zpool_${POOLNAME}.zdb_C.txt zpool_${POOLNAME}.zdb_l.*

