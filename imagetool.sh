#!/bin/bash

if [ "$(id -u)" != "0" ]; then
		echo "Please run as root" 1>&2
		exit 1
fi

progname=$(basename $0)

function usage()
{
	cat << HEREDOC

Usage:
    Mount Image : $progname [-m|--mount]     <path to qcow2 image> <mount point>
    Mount Image : $progname [-r|--mount-raw] <path to raw image>   <mount point>
    Umount Image: $progname [-u|--umount]    [-n <nbd-device>]     <mount point>
    Cleanup NBD : $progname [--cleanup]

   arguments:
     -h, --help           show this help message and exit
     -c, --cleanup        cleanup orphaned device mappings
     -C, --force-cleanup  forcefully cleanup orphaned or still connected device mappings
     -m, --mount          mount image
     -r, --mount-raw      mount raw image
     -u, --umount         umount image
     -n, --nbd-device     nbd device

   ./$progname --mount --image <your image> --mount-point <your path>

HEREDOC
}

MOUNT=0
RAW_IMAGE=0
UMOUNT=0
IMAGE=""
MOUNTPOINT=""
NBD_DEV=

nbd_cleanup() {
	DEVS="$(lsblk | grep nbd | grep disk | cut -d" " -f1)"
	if [ ! -z "${DEVS}" ]; then
		for d in $DEVS; do
			if [ ! -z "${d}" ]; then
				QDEV="$(ps xa | grep $d | grep -v grep)"
				if [ -z "${QDEV}" ]; then
					kpartx -d /dev/$d && echo "Unconnected device map removed: /dev/$d"
				fi
			fi
		done
	fi
}

force_nbd_cleanup() {
	DEVS="$(lsblk | grep nbd | grep disk | cut -d" " -f1)"
	if [ ! -z "${DEVS}" ]; then
		for d in $DEVS; do
			if [ ! -z "${d}" ]; then
				QDEV="$(ps xa | grep $d | grep -v grep)"
				if [ -z "${QDEV}" ]; then
					kpartx -d /dev/$d && echo "Unconnected device map removed: /dev/$d"
                else
					kpartx -d /dev/$d && echo "Connected device map removed (force): /dev/$d"
				fi
			fi
		done
	fi
}

find_nbd() {
    mntpoint="${1}"

	MAIN_DEVS="$(lsblk | grep nbd | grep disk | cut -d" " -f1)"
	if [ ! -z "${MAIN_DEVS}" ]; then
		for md in $MAIN_DEVS; do
			if [ ! -z "${md}" ]; then
                #SUB_DEVS="$(lsblk -l "/dev/${md}" | grep "${md}p" | cut -d" " -f1)"
                if lsblk -l "/dev/${md}" | grep "${mntpoint}" >& /dev/null ; then 
                    echo "/dev/${md}"
                    return 0;
                fi
			fi
		done
	fi
    return 1;
}

error_exit() {
    echo "$@"
    usage
    exit
}

# As long as there is at least one more argument, keep looping
while [[ $# -gt 0 ]]; do
	key="$1"
	case "$key" in
		-h|--help)
			usage
            exit
		;;
		-c|--cleanup)
			nbd_cleanup
            exit
		;;
		-C|--force-cleanup)
			force_nbd_cleanup
            exit
		;;
		-r|--mount-raw)
			MOUNT=1
            RAW_IMAGE=1
		;;
		-m|--mount)
			MOUNT=1
		;;
		-u|--umount)
			UMOUNT=1
		;;
		-n|--nbd-device)
			shift
			NBD_DEV="$1"
		;;
		*)
            if [ $MOUNT -eq 1 ]; then
                if [ -z "$IMAGE" ]; then
                    IMAGE=$1
                elif [ -z "$MOUNTPOINT" ]; then
                    MOUNTPOINT=$1
                else
                    error_exit "Unknown mount option '$key'"
                fi
            elif [ $UMOUNT -eq 1 ]; then
                if [ -z "$MOUNTPOINT" ]; then
                    MOUNTPOINT=$1
                else
                    error_exit "Unknown unmount option '$key'"
                fi
            else
                error_exit "Unknown option '$key'"
            fi
		;;
	esac
	# Shift after checking all the cases to get the next option
	shift
done

if [ "${MOUNT}" = "1" ] && [ "${UMOUNT}" = "1" ]; then
	usage
	echo "Concurrent mount options not possible."
	exit
fi

if [ "${MOUNT}" = "1" ] && ([ -z "${IMAGE}"  ] || [ -z "${MOUNTPOINT}"  ]); then
	usage
	echo "Can not mount image. Image path and/or mount point missing."
	exit
fi

if [ "${UMOUNT}" = "1" ] && [ -z "${MOUNTPOINT}" ]; then
	usage
	echo "Can not umount. Mount point parameter missing."
	exit
fi

if [ -n "${MOUNTPOINT}" -a ! -d "${MOUNTPOINT}" ]; then
    echo "Mountpoint ${MOUNTPOINT} not existing."
    exit 1
fi

if [ -n "${IMAGE}" -a ! -f "${IMAGE}" ]; then
    echo "Image ${IMAGE} not existing."
    exit 1
fi

source scripts/qcow2_handling

if [ "${MOUNT}" = "1" ]; then
    if [ "${RAW_IMAGE}" = "1" ]; then
        mount_rawimage "${IMAGE}" "${MOUNTPOINT}"
    else
        mount_qimage "${IMAGE}" "${MOUNTPOINT}"
    fi
    echo Using NBD_DEV $NBD_DEV
elif [ "${UMOUNT}" = "1" ]; then
    if [ -z "$NBD_DEV" ] ; then
        NBD_DEV=$(find_nbd ${MOUNTPOINT})
        if [ -z "${NBD_DEV}" ] ; then
            echo "umount: NBD_DEV not set and not found for ${MOUNTPOINT}. Exit."
            exit 1;
        fi
    fi
	umount_image "${MOUNTPOINT}"
fi
if [ ! -d "${MOUNTPOINT}" ]; then
    echo "Mountpoint ${MOUNTPOINT} not existing."
    exit 1
fi

source scripts/qcow2_handling

if [ "${MOUNT}" = "1" ]; then
    if [ "${RAW_IMAGE}" = "1" ]; then
        mount_rawimage "${IMAGE}" "${MOUNTPOINT}"
    else
        mount_qimage "${IMAGE}" "${MOUNTPOINT}"
    fi
    echo Using NBD_DEV $NBD_DEV
elif [ "${UMOUNT}" = "1" ]; then
    if [ -z "$NBD_DEV" ] ; then
        NBD_DEV=$(find_nbd ${MOUNTPOINT})
        if [ -z "${NBD_DEV}" ] ; then
            echo "umount: NBD_DEV not set and not found for ${MOUNTPOINT}. Exit."
            exit 1;
        fi
    fi
	umount_image "${MOUNTPOINT}"
fi
