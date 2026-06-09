#! /bin/bash

export dst_pool=backupdisk1
export dst_dset=backup-host
export snapname=host_20250505

bname=`basename $0 .sh`

function one_zsync()
{
    pool_dset=$1
    shift

    zfs snapshot -r ${pool_dset}@${snapname}

    zfs send -V -R ${pool_dset}@${snapname} | zfs receive -Fduv -x encryption -x mountpoint -o canmount=noauto ${dst_pool}/${dst_dset}
}

function one_zsync_enc()
{
    pool_dset=$1
    shift

    zfs snapshot -r ${pool_dset}@${snapname}

    #zfs send -V -Rw ${pool_dset}@${snapname} | zfs receive -Fduv -x encryption -o encryption=on -x mountpoint -o canmount=noauto ${dst_pool}/${dst_dset}
    zfs send -V -Rw ${pool_dset}@${snapname} | zfs receive -Fduv -x mountpoint -o canmount=noauto ${dst_pool}/${dst_dset}
}

function all_zsync()
{
    echo "Start $bname $snapname"

    one_zsync tpool/system
    one_zsync tpool/users
    one_zsync tpool/services
    one_zsync tpool/data
    one_zsync tpool/backup
    one_zsync tpool/data2
    one_zsync jordan/mysql

    ## zfs inherit -r mountpoint ${dst_pool}/${dst_dset}
    zfs list -r ${dst_pool}
    zfs list -r -t snapshot ${dst_pool}

    echo "End $bname $snapname"
}

logfile=${bname}.${snapname}.log

# all_zsync 2>&1 | tee $logfile
all_zsync >& $logfile &
disown $!

