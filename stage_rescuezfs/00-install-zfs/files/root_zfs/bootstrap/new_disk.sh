
NDISK1=ata-WDC_WD40EFZX-68AWUN0_WD-WX92DA0798JN
NDISK2=ata-WDC_WD40EFZX-68AWUN0_WD-WX92DA0791VU
NDISK3=ata-WDC_WD40EFZX-68AWUN0_WD-WX92DA02K427

# Clear the partition table:
sgdisk --zap-all /dev/disk/by-id/$NDISK1
#sgdisk --zap-all /dev/disk/by-id/$NDISK2
#sgdisk --zap-all /dev/disk/by-id/$NDISK3

# 2.2 Partition your disk:
#
# Run this if you need legacy (BIOS) booting:
sgdisk -a1 -n1:40:2047  -t1:EF02 /dev/disk/by-id/$NDISK1
#sgdisk -a1 -n1:40:2047  -t1:EF02 /dev/disk/by-id/$NDISK2
#sgdisk -a1 -n1:40:2047  -t1:EF02 /dev/disk/by-id/$NDISK3

#Run these in all cases:
sgdisk     -n2:0:0      -t2:BF01 /dev/disk/by-id/$NDISK1
#sgdisk     -n2:0:0      -t2:BF01 /dev/disk/by-id/$NDISK2
#sgdisk     -n2:0:0      -t2:BF01 /dev/disk/by-id/$NDISK3

echo "Now replace the disk .."
echo "zpool replace risa 12458555210078177352 /dev/disk/by-id/ata-WDC_WD40EFZX-68AWUN0_WD-WX92DA0798JN-part1"
