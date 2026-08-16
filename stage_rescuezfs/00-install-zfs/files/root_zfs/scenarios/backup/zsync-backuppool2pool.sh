#! /bin/bash

export src_pool=backup
export dst_pool=tpool
export snapname=backup3

bname=`basename $0 .sh`

function one_zsync()
{
    pool_dset=$1
    shift

    zfs snapshot -r ${pool_dset}@${snapname}

    zfs send -V -R ${pool_dset}@${snapname} | zfs receive -Fduv -x encryption -o canmount=noauto ${dst_pool}
}

function all_zsync()
{
    echo "Start $bname $snapname"

    one_zsync ${src_pool}

    zfs list -r ${dst_pool}
    zfs list -r -t snapshot ${dst_pool}

    # disable mount for next boot on backup
    zfs set canmount=off ${src_pool}/system
    zfs set canmount=off ${src_pool}/system/debian
    zfs set canmount=off ${src_pool}/system/debian/var
    zfs set canmount=off ${src_pool}/users
    zfs set canmount=off ${src_pool}/users/root

    echo "End $bname $snapname"
}

logfile=${bname}.${snapname}.log

# all_zsync 2>&1 | tee $logfile
all_zsync >& $logfile &
disown $!

