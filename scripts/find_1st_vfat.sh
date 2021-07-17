#!/bin/sh

find_blkpart() {
    local fstype_exp="$1"
    local res=""
    local blkparts=$(lsblk -l | grep part | cut -d" " -f1)
    if [ -z "${blkparts}" ]; then
        # May take some time on PC's after loading device modules (usb, ..)
        local blkpartwait=180
        while [ "$(time_elapsed)" -lt "$blkpartwait" ]; do
            blkparts=$(lsblk -l | grep part | cut -d" " -f1)
            if [ -n "${blkparts}" ]; then
                break
            fi
            sleep 1
        done
        if [ -z "${blkparts}" ]; then
            panic "loop_rootfs: Block devices did not appear in time"
            exit 1
        fi
    fi
    for i in ${blkparts} ; do
        local FSTYPE=$(blkid -o value -s TYPE /dev/$i)
        if [ "${FSTYPE}" = "${fstype_exp}" ]; then
            res="/dev/$i"
            break
        fi
    done
    echo -n "${res}"
}

BLKDEV=$(find_blkpart vfat)
echo "BLKDEV ${BLKDEV}"
