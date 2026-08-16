# Operates within one pool POOL
# - Creates DS_SRC snapshot
# - Sends DS_SRC into DS_SRC
#   - removes encryption and mountpoint, i.e. inherit from parent
#   - adds given options DS_DST_OPTS
# - Removes snapshots
# - Manually replacing w/
#   - zfs set mountpoint=/YOUR_MOUNT_POINT ${POOL}/${DS_DST}
#   - zfs rename -f ${POOL}/${DS_SRC} ${POOL}/${DS_SRC}_old
#   - zfs umount ${POOL}/${DS_SRC}_old ** not atomic **
#   - zfs mount ${POOL}/${DS_DST}      ** not atomic **
#   - zfs rename -f ${POOL}/${DS_DST} ${POOL}/${DS_SRC}
#   - zfs destroy -r ${POOL}/${DS_SRC}_old
#
# recordsize summary
# - 1MiB for general-purpose file sharing/storage
# - 1MiB for BitTorrent download folders—this minimizes the impact of fragmentation!
# - 64KiB for KVM virtual machines using Qcow2 file-based storage
# - 16KiB for MySQL InnoDB
# - 8KiB for PostgreSQL
# see
# - https://openzfs.github.io/openzfs-docs/Performance%20and%20Tuning/Workload%20Tuning.html
# - https://cr0x.net/en/zfs-recordsize-file-performance/
# - https://klarasystems.com/articles/tuning-recordsize-in-openzfs/
#
POOL=tpool
DS_SRC=data2
DS_DST=data2_copy
DS_DST_OPTS="-o recordsize=1M"

TIMESTAMP=`date +%Y%m%d-%H%M`
SNAPNAME=transfer_${TIMESTAMP}

zfs create ${DS_DST_OPTS} ${POOL}/${DS_DST}

zfs snapshot ${POOL}/${DS_SRC}@${SNAPNAME}
zfs list -r -t snapshot ${POOL}

zfs send -V ${POOL}/${DS_SRC}@${SNAPNAME} | zfs receive -Fuv -x encryption -x mountpoint ${DS_DST_OPTS} ${POOL}/${DS_DST}

zfs destroy -r ${POOL}/${DS_SRC}@${SNAPNAME}
zfs destroy -r ${POOL}/${DS_DST}@${SNAPNAME}

zfs list -r -t snapshot ${POOL}
zfs get -r mountpoint ${POOL}
zfs get -r recordsize ${POOL}
zfs get -r compression ${POOL}
#mount | grep ${POOL}

echo "Finalize replacing dataset ${DS_SRC} with ${DS_DST}"
echo "- zfs set mountpoint=/YOUR_MOUNT_POINT ${POOL}/${DS_DST}"
echo "- zfs rename -f ${POOL}/${DS_SRC} ${POOL}/${DS_SRC}_old"
echo "- zfs umount ${POOL}/${DS_SRC}_old"
echo "- zfs mount ${POOL}/${DS_DST}"
echo "- zfs rename -f ${POOL}/${DS_DST} ${POOL}/${DS_SRC}"
echo "- zfs destroy -r ${POOL}/${DS_SRC}_old"
