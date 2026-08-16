export POOL=tpool2
export SNAPNAME=transfer

export DS_SRC=system/debian/var
export DS_DST=system/debian/var2

export ZFS_COMPRESSION_METHOD=lz4
#export ZFS_COMPRESSION_METHOD=zstd

zfs create -o compression=${ZFS_COMPRESSION_METHOD} $POOL/$DS_DST

zfs snapshot $POOL/$DS_SRC@$SNAPNAME
zfs send -V ${POOL}/${DS_SRC}@${SNAPNAME} | zfs receive -Fuv -x encryption -x mountpoint -o compression=${ZFS_COMPRESSION_METHOD} ${POOL}/${DS_DST}

zfs destroy $POOL/$DS_SRC@$SNAPNAME
zfs destroy $POOL/$DS_DST@$SNAPNAME
