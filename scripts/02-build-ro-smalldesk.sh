#! /bin/sh

sdir=`dirname $(readlink -f $0)`
rootdir=`dirname $sdir`

export CUSTOM_NAME="MyMachine"
export CUSTOM_VERSION="1.1"

export PI_GEN="pi-gen (custom branch)"

# export RELEASE=bullseye
export RELEASE=buster

export TARGET_ARCH="arm64"

# export APT_PROXY=http://jordan:3142

# Produce a read-only rootfs
export ROOTFS_RO=1
export REDUCED_FOOTPRINT=1

export IMG_NAME="${CUSTOM_NAME}-${CUSTOM_VERSION}-${TARGET_ARCH}"
export WORK_DIR="/data/${CUSTOM_NAME}-${CUSTOM_VERSION}-${TARGET_ARCH}-work"
export IMG_FILENAME=${IMG_NAME}

export DEPLOY_DIR=/data/diskimages
export DEPLOY_ZIP=0

#export USE_QEMU=1

export TARGET_HOSTNAME=my502

export LOCALE_DEFAULT=en_US.UTF-8
export KEYBOARD_KEYMAP=us
export KEYBOARD_LAYOUT="English (US)"
export TIMEZONE_DEFAULT="Europe/Berlin"

export FIRST_USER_NAME="pi"
export FIRST_USER_PASS="pi"
export ENABLE_SSH=1
# export PUBKEY_SSH_FIRST_USER="ssh-rsa long-number my@machine"
# export PUBKEY_ONLY_SSH=1

# export STAGE_LIST="stage0 stage1 stage2 stage3a stage3b stage4 stage5"
export STAGE_LIST="stage0 stage1 stage2 stage3a stage3b"

touch ${rootdir}/stage2/SKIP_IMAGES
touch ${rootdir}/stage3a/SKIP_IMAGES
# touch ${rootdir}/stage3b/SKIP_IMAGES
# touch ${rootdir}/stage4/SKIP_IMAGES

./build.sh
