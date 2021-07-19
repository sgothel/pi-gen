#!/bin/bash -e

if [ "${TARGET_RASPI}" = "1" ]; then
    # B2 Console Autologin
    # B4 Desktop Autologin

    on_chroot << EOF
        SUDO_USER="${FIRST_USER_NAME}" raspi-config nonint do_boot_behaviour B4
EOF
fi
