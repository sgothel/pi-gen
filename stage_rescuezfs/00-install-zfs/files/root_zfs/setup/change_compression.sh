export POOL=tpool2
export SNAPNAME=transfer

export DSSRC=system/debian/var
export DSDST=system/debian/var2

export ZFS_COMPRESSION_METHOD=lz4
#export ZFS_COMPRESSION_METHOD=zstd

zfs create -o compression=${ZFS_COMPRESSION_METHOD} $POOL/$DSDST

zfs snapshot $POOL/$DSSRC@$SNAPNAME
#zfs send $POOL/$DSSRC@$SNAPNAME | zfs receive -Fduv -o compression=${ZFS_COMPRESSION_METHOD} $POOL/$DSDST
zfs send $POOL/$DSSRC@$SNAPNAME | zfs receive -Fuv -o compression=${ZFS_COMPRESSION_METHOD} $POOL/$DSDST

zfs destroy $POOL/$DSSRC@$SNAPNAME
zfs destroy $POOL/$DSDST@$SNAPNAME
