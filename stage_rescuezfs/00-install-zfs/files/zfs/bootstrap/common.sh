#!/bin/bash

log (){
	date +"[%T] $*" | tee -a "${LOG_FILE}"
}
export -f log

bootstrap(){
	local BOOTSTRAP_CMD=debootstrap
	local BOOTSTRAP_ARGS=()

	#export http_proxy=${APT_PROXY}

    # qemu-debootstrap is deprecated. Please use regular debootstrap directly
    #
	# if [ "$(dpkg --print-architecture)" !=  "armhf" ] && [ "$(dpkg --print-architecture)" !=  "arm64" ]; then
	#	 BOOTSTRAP_CMD=qemu-debootstrap
	# fi

	BOOTSTRAP_ARGS+=(--arch ${TARGET_ARCH})
	BOOTSTRAP_ARGS+=(--include gnupg)
	BOOTSTRAP_ARGS+=(--components "main,contrib,non-free")
	BOOTSTRAP_ARGS+=("$@")
	printf -v BOOTSTRAP_STR '%q ' "${BOOTSTRAP_ARGS[@]}"

	capsh --drop=cap_setfcap -- -c "'${BOOTSTRAP_CMD}' $BOOTSTRAP_STR" || true

	if [ -d "$2/debootstrap" ] && ! rmdir "$2/debootstrap"; then
		cp "$2/debootstrap/debootstrap.log" "${STAGE_WORK_DIR}"
		log "bootstrap failed: please check ${STAGE_WORK_DIR}/debootstrap.log"
		return 1
	fi
}
export -f bootstrap

apt_install() {
    DEBIAN_FRONTEND=noninteractive
    local APT_GET_INSTALL_OPTS='-o APT::Acquire::Retries=3'

    apt-get ${APT_GET_INSTALL_OPTS} install --no-install-recommends -y "$@"
}
export -f apt_install

apt_install_confdefold() {
    DEBIAN_FRONTEND=noninteractive
    local APT_GET_INSTALL_OPTS='-o APT::Acquire::Retries=3 -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"'

    apt-get ${APT_GET_INSTALL_OPTS} install --no-install-recommends -y "$@"
}
export -f apt_install

on_chroot() {
	if ! mount | grep -q "$(realpath "${ROOTFS_DIR}"/proc)"; then
		mount -t proc proc "${ROOTFS_DIR}/proc"
	fi

	if ! mount | grep -q "$(realpath "${ROOTFS_DIR}"/dev)"; then
		mount --bind /dev "${ROOTFS_DIR}/dev"
	fi
	
	if ! mount | grep -q "$(realpath "${ROOTFS_DIR}"/dev/pts)"; then
		mount --bind /dev/pts "${ROOTFS_DIR}/dev/pts"
	fi

	if ! mount | grep -q "$(realpath "${ROOTFS_DIR}"/sys)"; then
		mount --bind /sys "${ROOTFS_DIR}/sys"
	fi

    # run as root 'dpkg-reconfigure locales' enable 'en_US.UTF-8'
    # perhaps run as root 'update-locale LC_MEASUREMENT=en_US.UTF-8 LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8'
    export LC_MEASUREMENT=en_US.UTF-8
    export LC_ALL=en_US.UTF-8
    export LANG=en_US.UTF-8

	setarch linux32 capsh --drop=cap_setfcap "--chroot=${ROOTFS_DIR}/" -- -e "$@"
}
export -f on_chroot

