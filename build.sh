#!/bin/bash -e

export DEBIAN_FRONTEND=noninteractive

# shellcheck disable=SC2119
run_sub_stage()
{
    local APT_GET_INSTALL_OPTS='-o APT::Acquire::Retries=3 -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"'

    local packfile;
    local PACKAGES;
    log "Begin ${SUB_STAGE_DIR}"
    pushd "${SUB_STAGE_DIR}" > /dev/null
    for i in {00..99}; do
        if [ -f "${i}-debconf" ]; then
            log "Begin ${SUB_STAGE_DIR}/${i}-debconf"
            on_chroot << EOF
debconf-set-selections <<SELEOF
$(cat "${i}-debconf")
SELEOF
EOF

            log "End ${SUB_STAGE_DIR}/${i}-debconf"
        fi
        if [ "${TARGET_RASPI}" = "1" -a \( -f "${i}-packages-sys-raspi" -o -f "${i}-packages-sys-raspi-${RELEASE}" \) ]; then
            if [ -f "${i}-packages-sys-raspi-${RELEASE}" ]; then
                packfile="${i}-packages-sys-raspi-${RELEASE}"
            else
                packfile="${i}-packages-sys-raspi"
            fi
            log "Begin ${SUB_STAGE_DIR}/${packfile}"
            PACKAGES="$(sed -f "${SCRIPT_DIR}/remove-comments.sed" < "${packfile}")"
            if [ -n "$PACKAGES" ]; then
                on_chroot << EOF
echo "Installing ${packfile} '${PACKAGES}'"
apt-get ${APT_GET_INSTALL_OPTS} install --no-install-recommends -y $PACKAGES
EOF
                if [ "${USE_QCOW2}" = "1" ]; then
                    on_chroot << EOF
apt-get clean
EOF
                fi
            fi
            log "End ${SUB_STAGE_DIR}/${packfile}"
        elif [ "${TARGET_RASPI}" != "1" ]; then
            if [ -f "${i}-packages-sys-debian-${RELEASE}-${TARGET_ARCH}" ]; then
                packfile="${i}-packages-sys-debian-${RELEASE}-${TARGET_ARCH}"
            elif [ -f "${i}-packages-sys-debian-${RELEASE}" ]; then
                packfile="${i}-packages-sys-debian-${RELEASE}"
            elif [ -f "${i}-packages-sys-debian-${TARGET_ARCH}" ]; then
                packfile="${i}-packages-sys-debian-${TARGET_ARCH}"
            elif [ -f "${i}-packages-sys-debian" ]; then
                packfile="${i}-packages-sys-debian"
            else
                packfile=
            fi
            if [ -n "${packfile}" ]; then
                log "Begin ${SUB_STAGE_DIR}/${packfile}"
                PACKAGES="$(sed -f "${SCRIPT_DIR}/remove-comments.sed" < "${packfile}")"
                if [ -n "$PACKAGES" ]; then
                    on_chroot << EOF
echo "Installing ${packfile} '${PACKAGES}'"
apt-get ${APT_GET_INSTALL_OPTS} install --no-install-recommends -y $PACKAGES
EOF
                    if [ "${USE_QCOW2}" = "1" ]; then
                        on_chroot << EOF
apt-get clean
EOF
                    fi
                fi
                log "End ${SUB_STAGE_DIR}/${packfile}"
            fi
        fi
        if [ -f "${i}-packages-nr" -o -f "${i}-packages-nr-${RELEASE}" ]; then
            if [ -f "${i}-packages-nr-${RELEASE}" ]; then
                packfile="${i}-packages-nr-${RELEASE}"
            else
                packfile="${i}-packages-nr"
            fi
            log "Begin ${SUB_STAGE_DIR}/${packfile}"
            PACKAGES="$(sed -f "${SCRIPT_DIR}/remove-comments.sed" < "${packfile}")"
            if [ -n "$PACKAGES" ]; then
                on_chroot << EOF
echo "Installing ${packfile} '${PACKAGES}'"
apt-get ${APT_GET_INSTALL_OPTS} install --no-install-recommends -y $PACKAGES
EOF
                if [ "${USE_QCOW2}" = "1" ]; then
                    on_chroot << EOF
apt-get clean
EOF
                fi
            fi
            log "End ${SUB_STAGE_DIR}/${packfile}"
        fi
        if [ -f "${i}-packages" -o -f "${i}-packages-${RELEASE}" ]; then
            if [ -f "${i}-packages-${RELEASE}" ]; then
                packfile="${i}-packages-${RELEASE}"
            else
                packfile="${i}-packages"
            fi
            log "Begin ${SUB_STAGE_DIR}/${packfile}"
            PACKAGES="$(sed -f "${SCRIPT_DIR}/remove-comments.sed" < "${packfile}")"
            if [ -n "$PACKAGES" ]; then
                on_chroot << EOF
echo "Installing ${packfile} '${PACKAGES}'"
if [ "${INSTALL_RECOMMENDS}" != "1" -o "${REDUCED_FOOTPRINT}" = "1" ]; then
    apt-get ${APT_GET_INSTALL_OPTS} install --no-install-recommends -y $PACKAGES
else
    # "${INSTALL_RECOMMENDS}" = "1" -a "${REDUCED_FOOTPRINT}" != "1"
    apt-get ${APT_GET_INSTALL_OPTS} install -y $PACKAGES
fi
EOF
                if [ "${USE_QCOW2}" = "1" ]; then
                    on_chroot << EOF
apt-get clean
EOF
                fi
            fi
            log "End ${SUB_STAGE_DIR}/${packfile}"
        fi
        if [ -d "${i}-patches" ]; then
            log "Begin ${SUB_STAGE_DIR}/${i}-patches"
            pushd "${STAGE_WORK_DIR}" > /dev/null
            if [ "${CLEAN}" = "1" ]; then
                rm -rf .pc
                rm -rf ./*-pc
            fi
            QUILT_PATCHES="${SUB_STAGE_DIR}/${i}-patches"
            SUB_STAGE_QUILT_PATCH_DIR="$(basename "$SUB_STAGE_DIR")-pc"
            mkdir -p "$SUB_STAGE_QUILT_PATCH_DIR"
            ln -snf "$SUB_STAGE_QUILT_PATCH_DIR" .pc
            quilt upgrade
            if [ -e "${SUB_STAGE_DIR}/${i}-patches/EDIT" ]; then
                echo "Dropping into bash to edit patches..."
                bash
            fi
            RC=0
            quilt push -a || RC=$?
            case "$RC" in
                0|2)
                    ;;
                *)
                    false
                    ;;
            esac
            popd > /dev/null
            log "End ${SUB_STAGE_DIR}/${i}-patches"
        fi
        if [ -x ${i}-run.sh ]; then
            log "Begin ${SUB_STAGE_DIR}/${i}-run.sh"
            ./${i}-run.sh
            log "End ${SUB_STAGE_DIR}/${i}-run.sh"
        fi
        if [ -f ${i}-run-chroot.sh ]; then
            log "Begin ${SUB_STAGE_DIR}/${i}-run-chroot.sh"
            on_chroot < ${i}-run-chroot.sh
            log "End ${SUB_STAGE_DIR}/${i}-run-chroot.sh"
        fi
    done
    popd > /dev/null
    log "End ${SUB_STAGE_DIR}"
}


contains() { 
    if [[ $1 =~ (^|[[:space:]])$2($|[[:space:]]) ]]; then 
        echo -n "1"
    else 
        echo -n "0"
    fi 
}

run_stage(){
    STAGE="$(basename "${STAGE_DIR}")"
    SKIP_STAGE=`contains "${SKIP_STAGE_LIST}" ${STAGE}`
    SKIP_IMAGES=`contains "${SKIP_IMAGES_LIST}" ${STAGE}`
    log "Begin ${STAGE} ${STAGE_DIR} SKIP(STAGE ${SKIP_STAGE}, IMAGES ${SKIP_IMAGES})"

    pushd "${STAGE_DIR}" > /dev/null

    STAGE_WORK_DIR="${WORK_DIR}/${STAGE}"
    ROOTFS_DIR="${STAGE_WORK_DIR}"/rootfs

    if [ "${USE_QCOW2}" = "1" ]; then 
        if [ "${SKIP_STAGE}" != "1" ]; then
            load_qimage
        fi
    fi
    
    if [ "${SKIP_IMAGES}" != "1" ]; then
        if [ -f "${STAGE_DIR}/EXPORT_IMAGE" ]; then
            EXPORT_DIRS="${EXPORT_DIRS} ${STAGE_DIR}"
        fi
    fi
    if [ "${SKIP_STAGE}" != "1" ]; then
        if [ "${CLEAN}" = "1" ] && [ "${USE_QCOW2}" = "0" ] ; then
            if [ -d "${ROOTFS_DIR}" ]; then
                rm -rf "${ROOTFS_DIR}"
            fi
        fi
        if [ -x prerun.sh ]; then
            log "Begin ${STAGE_DIR}/prerun.sh"
            ./prerun.sh
            log "End ${STAGE_DIR}/prerun.sh"
        fi
        for SUB_STAGE_DIR in "${STAGE_DIR}"/*; do
            if [ -d "${SUB_STAGE_DIR}" ]; then
                run_sub_stage
            fi
        done
    fi

    if [ "${USE_QCOW2}" = "1" ]; then 
        unload_qimage
    fi

    PREV_STAGE="${STAGE}"
    PREV_STAGE_DIR="${STAGE_DIR}"
    PREV_ROOTFS_DIR="${ROOTFS_DIR}"
    popd > /dev/null
    log "End ${STAGE_DIR}"
}

if [ "$(id -u)" != "0" ]; then
    echo "Please run as root" 1>&2
    exit 1
fi

BASE_DIR=`dirname $(readlink -f "${BASH_SOURCE[0]}")`
export BASE_DIR
export SCRIPT_DIR="${BASE_DIR}/scripts"

source "${SCRIPT_DIR}/build_vars"

CLEAN=1
mkdir -p "${WORK_DIR}"
log "Begin ${BASE_DIR}"

STAGE_LIST=${STAGE_LIST:-${BASE_DIR}/stage*}
echo "Running  stages: \"${STAGE_LIST}\""

SKIP_STAGE_LIST=${SKIP_STAGE_LIST:-}
SKIP_IMAGES_LIST=${SKIP_IMAGES_LIST:-}
echo "Skipping stages: \"${SKIP_STAGE_LIST}\""
echo "Skipping images: \"${SKIP_IMAGES_LIST}\""

for STAGE_DIR in $STAGE_LIST; do
    STAGE_DIR=$(realpath "${STAGE_DIR}")
    run_stage
done

CLEAN=1
for EXPORT_DIR in ${EXPORT_DIRS}; do
    STAGE_DIR=${BASE_DIR}/export-image
    # shellcheck source=/dev/null
    source "${EXPORT_DIR}/EXPORT_IMAGE"
    EXPORT_ROOTFS_DIR=${WORK_DIR}/$(basename "${EXPORT_DIR}")/rootfs
    USE_QCOW2=0
    EXPORT_NAME="${IMG_FILENAME}${IMG_SUFFIX}"
    echo "------------------------------------------------------------------------"
    echo "Running export stage for ${EXPORT_NAME}"
    rm -f "${WORK_DIR}/export-image/${EXPORT_NAME}.img" || true
    rm -f "${WORK_DIR}/export-image/${EXPORT_NAME}.qcow2" || true
    rm -rf "${WORK_DIR}/export-image/rootfs" || true
    rm -f "${WORK_DIR}/${EXPORT_NAME}.img" || true
    rm -f "${WORK_DIR}/${EXPORT_NAME}.qcow2" || true
    EXPORT_STAGE=$(basename "${EXPORT_DIR}")
    for s in $STAGE_LIST; do
        TMP_LIST=${TMP_LIST:+$TMP_LIST }$(basename "${s}")
    done
    FIRST_STAGE=${TMP_LIST%% *}
    FIRST_IMAGE="image-${FIRST_STAGE}.qcow2"

    pushd "${WORK_DIR}" > /dev/null
    echo "Creating new base "${EXPORT_NAME}.qcow2" from ${FIRST_IMAGE}"
    cp "./${FIRST_IMAGE}" "${EXPORT_NAME}.qcow2"

    ARR=($TMP_LIST)
    # rebase stage images to new export base
    for CURR_STAGE in "${ARR[@]}"; do
        if [ "${CURR_STAGE}" = "${FIRST_STAGE}" ]; then
            PREV_IMG="${EXPORT_NAME}"
            continue
        fi
        echo "Rebasing image-${CURR_STAGE}.qcow2 onto ${PREV_IMG}.qcow2"
        qemu-img rebase -f qcow2 -u -b ${PREV_IMG}.qcow2 image-${CURR_STAGE}.qcow2 -F qcow2
        if [ "${CURR_STAGE}" = "${EXPORT_STAGE}" ]; then
            break
        fi
        PREV_IMG="image-${CURR_STAGE}"
    done

    # commit current export stage into base export image
    echo "Committing image-${EXPORT_STAGE}.qcow2 to ${EXPORT_NAME}.qcow2"
    qemu-img commit -f qcow2 -p -b "${EXPORT_NAME}.qcow2" image-${EXPORT_STAGE}.qcow2

    # rebase stage images back to original first stage for easy re-run
    for CURR_STAGE in "${ARR[@]}"; do
        if [ "${CURR_STAGE}" = "${FIRST_STAGE}" ]; then
            PREV_IMG="image-${CURR_STAGE}"
            continue
        fi
        echo "Rebasing back image-${CURR_STAGE}.qcow2 onto ${PREV_IMG}.qcow2"
        qemu-img rebase -f qcow2 -u -b ${PREV_IMG}.qcow2 image-${CURR_STAGE}.qcow2 -F qcow2
        PREV_ROOTFS_DIR="${WORK_DIR}/${CURR_STAGE}"/rootfs
        if [ "${CURR_STAGE}" = "${EXPORT_STAGE}" ]; then
            break
        fi
        PREV_IMG="image-${CURR_STAGE}"
    done
    popd > /dev/null

    mkdir -p "${WORK_DIR}/export-image/rootfs"
    if [[ "${ROOTFS_RO}" = "1" && -n "${PREV_ROOTFS_DIR}" ]]; then
        echo "ROOTFS_RO: rsync ${PREV_ROOTFS_DIR}/ ${WORK_DIR}/export-image/rootfs"
        rsync -a "${PREV_ROOTFS_DIR}/" "${WORK_DIR}/export-image/rootfs"
        sync
    fi
    mv "${WORK_DIR}/${EXPORT_NAME}.qcow2" "${WORK_DIR}/export-image/"
    echo "Mounting image ${WORK_DIR}/export-image/${EXPORT_NAME}.qcow2 to rootfs ${WORK_DIR}/export-image/rootfs"
    mount_qimage "${WORK_DIR}/export-image/${EXPORT_NAME}.qcow2" "${WORK_DIR}/export-image/rootfs"

    CLEAN=0
    run_stage
    CLEAN=1
    USE_QCOW2=1

    if [ "${USE_QEMU}" != "1" ]; then
        if [ -e "${EXPORT_DIR}/EXPORT_NOOBS" ]; then
            # shellcheck source=/dev/null
            source "${EXPORT_DIR}/EXPORT_NOOBS"
            STAGE_DIR="${BASE_DIR}/export-noobs"
            USE_QCOW2=0
            run_stage
            USE_QCOW2=1
        fi
    fi
done

if [ -x postrun.sh ]; then
    log "Begin postrun.sh"
    cd "${BASE_DIR}"
    ./postrun.sh
    log "End postrun.sh"
fi

unload_qimage

log "End ${BASE_DIR}"
