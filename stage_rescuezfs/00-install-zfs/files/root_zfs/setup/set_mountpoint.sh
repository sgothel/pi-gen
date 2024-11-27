export POOL=tpool2

zfs set -u mountpoint=/backup              $POOL/backup
zfs set -u mountpoint=/data                $POOL/data
zfs set -u mountpoint=/usr/local/projects  $POOL/projects
zfs set -u mountpoint=/srv                 $POOL/services
zfs set -u mountpoint=/                    $POOL/system/debian
zfs set -u mountpoint=/home                $POOL/users
zfs set -u mountpoint=/root                $POOL/users/root

