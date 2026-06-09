#!/bin/bash

zfs create -o encryption=on -o keyformat=passphrase $1

#zfs mount $POOL/backup-hostname
#zfs unmount $POOL/backup-hostname
#zfs unload-key $POOL/backup-hostname
#zfs load-key $POOL/backup-hostname

