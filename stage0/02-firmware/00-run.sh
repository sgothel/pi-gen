#!/bin/bash -e

if [ "${TARGET_RASPI}" != "1" ]; then
    on_chroot << EOF
        if [ "${TARGET_ARCH}" = "amd64" -o "${TARGET_ARCH}" = "i386" ]; then
            apt-get -o APT::Acquire::Retries=3 install --no-install-recommends -y amd64-microcode intel-microcode
        fi
        apt-get -o APT::Acquire::Retries=3 install --no-install-recommends -y linux-image-${TARGET_ARCH}
EOF
fi
