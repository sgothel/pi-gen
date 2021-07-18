#!/bin/bash

if [ "$(id -u)" != "0" ]; then
		echo "Please run as root" 1>&2
		exit 1
fi

rootdir=`dirname $(readlink -f "${BASH_SOURCE[0]}")`

source ${rootdir}/scripts/lib_nbd_img_handling

progname=$(basename $0)

function usage()
{
	cat << HEREDOC

Usage:
    Mount Image : $progname [--connect]      <path to qcow2 image>
    Mount Image : $progname [--connect-raw]  <path to raw image>
    Mount Image : $progname [--disconnect]   <nbd device basename>
    Mount Image : $progname [-m|--mount]     <path to qcow2 image> <mount point>
    Mount Image : $progname [-r|--mount-raw] <path to raw image>   <mount point>
    Umount Image: $progname [-u|--umount]                          <mount point>
    Cleanup NBD : $progname [--cleanup]

   arguments:
     -h, --help           show this help message and exit
     -c, --cleanup        cleanup orphaned device mappings
     -C, --force-cleanup  forcefully cleanup orphaned or still connected device mappings
     --connect            connect qcow2 image
     --connect-raw        connect raw image
     --disconnect         disconnect connected qcow2 image
     -m, --mount          mount qcow2 image
     -r, --mount-raw      mount raw image
     -u, --umount         umount image

   ./$progname --mount --image <your image> --mount-point <your path>

HEREDOC
}

CONNECT=0
DISCONNECT=0
MOUNT=0
RAW_IMAGE=0
UMOUNT=0
IMAGE=""
MOUNTPOINT=""
NBD_BASENAME=""

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
			lib_nbd_cleanup
            exit
		;;
		-C|--force-cleanup)
			lib_force_nbd_cleanup
            exit
		;;
		--connect-raw)
			CONNECT=1
            RAW_IMAGE=1
		;;
		--connect)
			CONNECT=1
		;;
		--disconnect)
			DISCONNECT=1
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
		*)
            if [ $CONNECT -eq 1 ]; then
                if [ -z "$IMAGE" ]; then
                    IMAGE=$1
                else
                    error_exit "Unknown connect option '$key'"
                fi
            elif [ $DISCONNECT -eq 1 ]; then
                if [ -z "$NBD_BASENAME" ]; then
                    NBD_BASENAME=$1
                else
                    error_exit "Unknown disconnect option '$key'"
                fi
            elif [ $MOUNT -eq 1 ]; then
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

CTR_MOUNTCONN=0
if [ "${MOUNT}" = "1" ]; then
    let CTR_MOUNTCONN=${CTR_MOUNTCONN}+1
fi
if [ "${UMOUNT}" = "1" ]; then
    let CTR_MOUNTCONN=${CTR_MOUNTCONN}+1
fi
if [ "${CONNECT}" = "1" ]; then
    let CTR_MOUNTCONN=${CTR_MOUNTCONN}+1
fi
if [ "${DISCONNECT}" = "1" ]; then
    let CTR_MOUNTCONN=${CTR_MOUNTCONN}+1
fi
if [ "${CTR_MOUNTCONN}" -gt 1 ]; then
	usage
	echo "Concurrent mount/connect options not possible."
	exit
fi

if [ "${CONNECT}" = "1" ] && [ -z "${IMAGE}" ]; then
	usage
	echo "Can not connect to image. Image path missing."
	exit
fi

if [ "${DISCONNECT}" = "1" ] && [ -z "${NBD_BASENAME}" ]; then
	usage
	echo "Can not disconnect nbd device. NBD basename missing."
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

if [ "${CONNECT}" = "1" ]; then
    nbd_dev=
    if [ "${RAW_IMAGE}" = "1" ]; then
        nbd_dev=$(lib_connect_blkdev2 "${IMAGE}" "raw")
    else
        nbd_dev=$(lib_connect_blkdev2 "${IMAGE}" "qcow2")
    fi
    echo ${nbd_dev}
elif [ "${DISCONNECT}" = "1" ]; then
    lib_disconnect_blkdev "${NBD_BASENAME}"
elif [ "${MOUNT}" = "1" ]; then
    nbd_dev=
    if [ "${RAW_IMAGE}" = "1" ]; then
        nbd_dev=$(lib_mount_image3 "${IMAGE}" "raw" "${MOUNTPOINT}")
    else
        nbd_dev=$(lib_mount_image3 "${IMAGE}" "qcow2" "${MOUNTPOINT}")
    fi
    echo ${nbd_dev}
elif [ "${UMOUNT}" = "1" ]; then
    lib_umount_image1 "${MOUNTPOINT}"
fi

