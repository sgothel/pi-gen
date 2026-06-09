#!/bin/bash

export POOL=tpool2

zpool set feature@allocation_classes=enabled $POOL
zpool set feature@async_destroy=enabled $POOL
zpool set feature@block_cloning=enabled $POOL
zpool set feature@bookmarks=enabled $POOL
zpool set feature@device_rebuild=enabled $POOL
zpool set feature@embedded_data=enabled $POOL
zpool set feature@empty_bpobj=enabled $POOL
zpool set feature@enabled_txg=enabled $POOL
zpool set feature@extensible_dataset=enabled $POOL
zpool set feature@filesystem_limits=enabled $POOL
zpool set feature@hole_birth=enabled $POOL
zpool set feature@large_blocks=enabled $POOL
zpool set feature@livelist=enabled $POOL
zpool set feature@log_spacemap=enabled $POOL
zpool set feature@lz4_compress=enabled $POOL
zpool set feature@project_quota=enabled $POOL
zpool set feature@resilver_defer=enabled $POOL
zpool set feature@spacemap_histogram=enabled $POOL
zpool set feature@spacemap_v2=enabled $POOL
zpool set feature@userobj_accounting=enabled $POOL
zpool set feature@zilsaxattr=enabled $POOL
zpool set feature@zpool_checkpoint=enabled $POOL

