#! /bin/bash

export dst_ssh=root@remote
export snapname=host_20250505

bname=`basename $0 .sh`

function one_zsync()
{
    src_dset=$1
    shift
    dst_dset=$1
    shift

    zfs snapshot -r ${src_dset}@${snapname}

    zfs send -V -R ${src_dset}@${snapname} | ssh ${dst_ssh} "zfs receive -Fduv -x encryption -x mountpoint -o canmount=noauto ${dst_dset}"
}

function all_zsync()
{
    echo "Start $bname"

    one_zsync tpool/projects             remote_pool/backup/host

    ssh ${dst_ssh} "zfs list -r remote_pool/backup/host"
    ssh ${dst_ssh} "zfs list -r -t snapshot remote_pool/backup/host"

    echo "End $bname"
}

logfile=${bname}.${snapname}.log

# all_zsync 2>&1 | tee $logfile
all_zsync >& $logfile &
disown $!

