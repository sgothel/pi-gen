#!/bin/bash -e

if [ "${TARGET_RASPI}" != "1" ]; then
    on_chroot << EOF
        apt-get -o APT::Acquire::Retries=3 install --no-install-recommends -y linux-headers-${TARGET_ARCH}
EOF
fi

if [ "${RELEASE}" = "buster" -a "${TARGET_ARCH}" = "armhf" ]; then
    # cmake hangs with qemu-arm-static
    # https://bugs.launchpad.net/qemu/+bug/955379
    # Fixed in cmake 3.18+

    # cmake-data cmake cmake-extras extra-cmake-modules pkg-config
    # cmake-data cmake
    on_chroot << EOF
        dpkg -P cmake cmake-data
EOF
    tar xa -C "${ROOTFS_DIR}/usr/local" -f files/cmake-3.18.4-deb10_armhf.tar.xz
fi

