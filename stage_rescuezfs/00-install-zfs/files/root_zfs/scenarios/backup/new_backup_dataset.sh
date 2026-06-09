
POOL=apool
ZFS_COMPRESSION_METHOD=lz4

zfs create -o mountpoint=/backup/hostname/projects -o compression=${ZFS_COMPRESSION_METHOD} $POOL/backup/hostname/projects
