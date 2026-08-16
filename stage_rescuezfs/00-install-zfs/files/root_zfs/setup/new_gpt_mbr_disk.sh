
NDISK1=ata-WDC_WD40EFZX-68AWUN0_WD-WX92DA0798JN
NDISK2=ata-WDC_WD40EFZX-68AWUN0_WD-WX92DA0791VU
NDISK3=ata-WDC_WD40EFZX-68AWUN0_WD-WX92DA02K427

# EF02 Bios-Boot (Grub core)
# 8200 Linux Swap
# BF01 ZFS Root
for dname in "${NDISK1}" "${NDISK2}" "${NDISK3}" ; do
    sgdisk --zap-all \
      --set-alignment=4096 --align-end \
      --new 1::+1MiB   --typecode=1:EF02 \
      --new 2::+64GiB  --typecode=2:8200 \
      --new 3::0       --typecode=3:BF01 \
      "/dev/disk/by-id/${dname}"
done

sleep 3
sync

echo "Now replace the disk .."
echo "zpool replace POOL <removed-disk-id-1> /dev/disk/by-id/${NDISK1}-part3"
echo "zpool replace POOL <removed-disk-id-2> /dev/disk/by-id/${NDISK2}-part3"
echo "zpool replace POOL <removed-disk-id-3> /dev/disk/by-id/${NDISK3}-part3"
