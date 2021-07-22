
ROOTFS_DIR=

if true ; then

install -m 644 resize2fs_once.service	        "${ROOTFS_DIR}/lib/systemd/system/"
install -m 755 resize2fs_once	                "${ROOTFS_DIR}/etc/init.d/"

systemctl unmask resize2fs_once
systemctl enable resize2fs_once

else

systemctl disable resize2fs_once
systemctl mask resize2fs_once

fi
