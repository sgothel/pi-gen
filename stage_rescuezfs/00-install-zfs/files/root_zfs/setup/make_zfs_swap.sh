#!/bin/bash

#
# WARNING: ZFS ZVOL swap on Linux is buggy!
# See <https://github.com/openzfs/zfs/issues/7734>
#

export MYSWAPSIZE=64G

export POOL=tpool2

if [ ! -z "$MYSWAPSIZE" ]; then
    # SWAP
    zfs create -V ${MYSWAPSIZE} \
          -b $(getconf PAGESIZE) \
          -o compression=off \
          -o dedup=off \
          -o checksum=off \
          -o logbias=throughput -o sync=always \
          -o primarycache=metadata -o secondarycache=none \
          -o com.sun:auto-snapshot=false $POOL/swap

    # vm.swappiness=10 or even lower?
    # sync=standard for speed-up, but perhaps not freeing mem asap

    mkswap -f /dev/zvol/$POOL/swap
    echo /dev/zvol/$POOL/swap none swap defaults 0 0 >> /etc/fstab
    # UUID=ee57ce05-7287-4b37-93c4-03aeaba756f1
    # /etc/fstab
    # /dev/zvol/$POOL/swap   none  		   swap    defaults  0  0
    # 
    # swapon /dev/zvol/$POOL/swap
    #
    echo "Swap: /etc/fstab modified"
    echo "Swap: Enable: swapon /dev/zvol/$POOL/swap"
fi

