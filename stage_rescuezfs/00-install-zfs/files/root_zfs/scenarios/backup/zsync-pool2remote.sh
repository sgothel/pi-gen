#! /bin/bash

export src_pool=LocalPool
export dst_pool=RemotePool

# ssh dst_pool remote access
export remote_ssh=root@remote

# end of config
export snapname=${src_pool}_$(date +%Y-%m-%d-%H%M)

bname=`basename $0 .sh`

function one_zsync()
{
    src_dset=$1
    shift
    dst_dset=$1
    shift

    zfs snapshot -r ${src_dset}@${snapname}
    zfs send -V -R ${src_dset}@${snapname} | ssh ${remote_ssh} "zfs receive -Fduv -x encryption -x mountpoint -o canmount=noauto ${dst_dset}"
}

function all_zsync()
{
    echo "Start $bname"

    ssh ${remote_ssh} "zfs create ${dst_pool}/backup/${src_pool}"

    one_zsync ${src_pool}/projects ${dst_pool}/backup/${src_pool}

    ssh ${remote_ssh} "zfs list -r ${dst_pool}/backup/${src_pool}"
    ssh ${remote_ssh} "zfs list -r -t snapshot ${dst_pool}/backup/${src_pool}"

    echo "End $bname"
}

logfile=${bname}.${snapname}.log

# all_zsync 2>&1 | tee $logfile
all_zsync >& $logfile &
disown $!

