
NDISK1=ata-QEMU_HARDDISK_QM00007
NDISK2=ata-QEMU_HARDDISK_QM00009
NDISK3=ata-QEMU_HARDDISK_QM00011

# EF02 Bios-Boot (Grub core)
# EF00 EFI System
# 8200 Linux Swap
# BF01 ZFS Root
for dname in "${NDISK1}" "${NDISK2}" "${NDISK3}" ; do
    sgdisk --zap-all \
      --set-alignment=4096 --align-end \
      --new 1::+1MiB   --typecode=1:EF02 \
      --new 2::+700MiB --typecode=2:EF00 \
      --new 3::+64GiB  --typecode=3:8200 \
      --new 4::0       --typecode=4:BF01 \
      "/dev/disk/by-id/${dname}"
done

sleep 3
sync

# Create EFI filesystems
mkfs.fat -n EFISYS -F32 /dev/disk/by-id/$NDISK1-part2
mkfs.fat -n EFISYS -F32 /dev/disk/by-id/$NDISK2-part2
mkfs.fat -n EFISYS -F32 /dev/disk/by-id/$NDISK3-part2

echo "Now replace the disk .."
echo "zpool replace POOL <removed-disk-id-1> /dev/disk/by-id/${NDISK1}-part4"
echo "zpool replace POOL <removed-disk-id-2> /dev/disk/by-id/${NDISK2}-part4"
echo "zpool replace POOL <removed-disk-id-3> /dev/disk/by-id/${NDISK3}-part4"
