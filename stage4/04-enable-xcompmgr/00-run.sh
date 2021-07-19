#!/bin/bash -e
 
if [ "${TARGET_RASPI}" = "1" ]; then
    on_chroot << EOF
           raspi-config nonint do_xcompmgr 0
EOF
fi
