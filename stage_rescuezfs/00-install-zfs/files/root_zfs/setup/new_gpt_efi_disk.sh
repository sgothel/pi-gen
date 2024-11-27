
NDISK1=ata-QEMU_HARDDISK_QM00007
NDISK2=ata-QEMU_HARDDISK_QM00009
NDISK3=ata-QEMU_HARDDISK_QM00011

# Clear the partition table:
sgdisk --zap-all /dev/disk/by-id/$NDISK1
sgdisk --zap-all /dev/disk/by-id/$NDISK2
sgdisk --zap-all /dev/disk/by-id/$NDISK3

# 2.2 Partition your disk:
#
# Legacy (BIOS) booting (part-1): Used for GRUB boot-code in 'MBR-gap':
sgdisk -a1 -n1:40:8191 -t1:EF02 /dev/disk/by-id/$NDISK1
sgdisk -a1 -n1:40:8191 -t1:EF02 /dev/disk/by-id/$NDISK2
sgdisk -a1 -n1:40:8191 -t1:EF02 /dev/disk/by-id/$NDISK3

# Run this if you need legacy (EFI) booting:
sgdisk     -n2:0:+1G  -t2:EF00 /dev/disk/by-id/$NDISK1
sgdisk     -n2:0:+1G  -t2:EF00 /dev/disk/by-id/$NDISK2
sgdisk     -n2:0:+1G  -t2:EF00 /dev/disk/by-id/$NDISK3

#Run these in all cases:
sgdisk     -n3:0:0      -t3:BF01 /dev/disk/by-id/$NDISK1
sgdisk     -n3:0:0      -t3:BF01 /dev/disk/by-id/$NDISK2
sgdisk     -n3:0:0      -t3:BF01 /dev/disk/by-id/$NDISK3

sleep 3
sync

# Create EFI filesystems
mkfs.fat -F32 /dev/disk/by-id/$NDISK1-part2
mkfs.fat -F32 /dev/disk/by-id/$NDISK2-part2
mkfs.fat -F32 /dev/disk/by-id/$NDISK3-part2

echo "Now replace the disk .."
echo "zpool replace risa 12458555210078177352 /dev/disk/by-id/ata-WDC_WD40EFZX-68AWUN0_WD-WX92DA0798JN-part1"
