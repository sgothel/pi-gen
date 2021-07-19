#!/bin/bash -e

if [ "${TARGET_RASPI}" != "1" ]; then
    on_chroot << EOF
        apt-get -o APT::Acquire::Retries=3 install --no-install-recommends -y linux-headers-${TARGET_ARCH}
EOF
fi
