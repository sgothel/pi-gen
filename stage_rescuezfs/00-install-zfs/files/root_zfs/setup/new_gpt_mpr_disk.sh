
NDISK1=ata-WDC_WD40EFZX-68AWUN0_WD-WX92DA0798JN
NDISK2=ata-WDC_WD40EFZX-68AWUN0_WD-WX92DA0791VU
NDISK3=ata-WDC_WD40EFZX-68AWUN0_WD-WX92DA02K427

# EF02 Bios-Boot (Grub core)
# BF01 ZFS Root
for dname in "${NDISK1}" "${NDISK2}" "${NDISK3}" ; do
    sgdisk --zap-all \
      --new 1::+1M   --typecode=1:EF02 \
      --new 2::0     --typecode=2:BF01 \
      "/dev/disk/by-id/${dname}"
done

sync

echo "Now replace the disk .."
echo "zpool replace risa 12458555210078177352 /dev/disk/by-id/ata-WDC_WD40EFZX-68AWUN0_WD-WX92DA0798JN-part1"
