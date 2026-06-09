export ROOTFS_DIR="/mnt"
export POOL1=tpool
export POOL2=tpool2
export SNAPNAME=transfer

zfs snapshot -r $POOL1@$SNAPNAME
zfs send -R $POOL1@$SNAPNAME | zfs receive -Fduv $POOL2

zfs destroy -r $POOL1@$SNAPNAME
zfs destroy -r $POOL2@$SNAPNAME

# now re-import on $ROOTFS_DIR w/ mounting
zpool export $POOL2
zpool import -R $ROOTFS_DIR $POOL

# Maintenance
echo
echo "$POOL2 mountpoints"
zfs get -r mountpoint $POOL2

echo
echo "$POOL2 compression"
zfs get -r compression $POOL2

echo
echo "$POOL2 snapshots"
zfs list -r -t snapshot $POOL2

# follow
# - ../rescue/chroot_zfs.sh to update grub on new pool
