#! /bin/bash

export src_pool=RemotePool
export dst_pool=LocalPool

# ssh src_pool remote access
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
    snapname_start=$1
    shift

    ssh ${remote_ssh} "zfs snapshot -r ${src_dset}@${snapname}"

    if [ -z "${snapname_start}" ] ; then
        ssh ${remote_ssh} "zfs send -V -R ${src_dset}@${snapname}" | \
        zfs receive -Fduv -x encryption -x mountpoint -o canmount=noauto ${dst_dset}
    else
        ssh ${remote_ssh} "zfs send -V -R -I @${snapname_start} ${src_dset}@${snapname}" | \
        zfs receive -Fduv -x encryption -x mountpoint -o canmount=noauto ${dst_dset}
    fi
}

function all_zsync()
{
    echo "Start $bname"

    zfs create ${dst_pool}/backup/${src_pool}

    # Initial
    one_zsync ${src_pool}/data      ${dst_pool}/backup/${src_pool}
    one_zsync ${src_pool}/mysql     ${dst_pool}/backup/${src_pool}
    one_zsync ${src_pool}/services  ${dst_pool}/backup/${src_pool}
    one_zsync ${src_pool}/users     ${dst_pool}/backup/${src_pool}
    one_zsync ${src_pool}/system    ${dst_pool}/backup/${src_pool}

    # Incremental
    #one_zsync ${src_pool}/data ${dst_pool}/backup/${src_pool} previous_snap_name

    zfs list -r ${dst_pool}/backup/${src_pool}
    zfs list -r -t snapshot ${dst_pool}/backup/${src_pool}

    echo "End $bname"
}

logfile=${bname}.${snapname}.log

# all_zsync 2>&1 | tee $logfile
all_zsync >& $logfile &
disown $!

