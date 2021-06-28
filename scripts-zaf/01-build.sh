#! /bin/sh

sdir=`dirname $(readlink -f $0)`
rootdir=`dirname $sdir`

export PI_GEN="pi-gen (Zafena branch)"
export PI_GEN_REPO="http://kontorsserver.zafena.se/sgothel/pi-gen"

# export RELEASE=bullseye
export RELEASE=buster

export APT_PROXY=http://jordan:3142

# ZAFENA_VERSION: major-version . minor.version - client . client-build
export ZAFENA_VERSION='1.1-0.6'

export IMG_NAME="zafcon-${ZAFENA_VERSION}"
export WORK_DIR="/data/zafcon_arm64_${ZAFENA_VERSION}-work"
export IMG_FILENAME=${IMG_NAME}

export DEPLOY_DIR=/data/diskimages
export DEPLOY_ZIP=0

#export USE_QEMU=1

export TARGET_HOSTNAME=raspi

export LOCALE_DEFAULT=en_US.UTF-8
export KEYBOARD_KEYMAP=us
export KEYBOARD_LAYOUT="English (US)"
export TIMEZONE_DEFAULT="Europe/Berlin"

export FIRST_USER_NAME="pi"
export FIRST_USER_PASS="zafena"
export ENABLE_SSH=1
export PUBKEY_SSH_FIRST_USER="ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAgEAm2qfo3uiWT9V7E/sH6unVO6XhGHeNnGUswxuADwFAKyflJq2yCALWIX7+DzEhBc7O9HxVztZAHLA+lfEpctQkA7KPgX98rjLHJlrm1lQXCPjwWjTZBrGNCmjWpYkc8jew/BzngmiwDlshYqzp0rWKNvQbkGJaVctqaraJAzE3F2wa+KkSBQuw2rAhiarbiO4MtO1AIw25EnSXHhP9EpeTKhAniKm73q977m5wpzaU+uwoGPCIyVl+BeaGLbPPIF35PJbg4tIqG6WLy3a8++Mf5Ml8lETcYYfjh4er3CvqFLhAYcaCLPNOwkK/YT4UnYZoZ4nt0Z+JWjxeNhIuJf64neysBdgB5E5FEYP2iYH+EUjcYp7YCrl/3/ag4Z2KAsF2qEa6/+s90Clm0r2mqRcQyLYQ6Co1YlYa1/jq7qsiuNgWvn5Mg8Pt4+L/C0KoycvUr4HhTS8EBJx+774p2uBa3mB65Vg2llKb8DdtQwR1bh0Ot9cjKTJY0pDyPiFbemZh2q7qD958bsOZCly43WYRd6E0Df68Q2MTz6ZC1y+z103gsEiK8bXmZp42ghDa96Ik2JO6pWCEUjBJ/9+rdudRHcfDlBqoS6+wg/z+WvtRtEyvVO4LSTrsX5xHWzVloSZeAGowmLbxGWHGWfl5oCcNfUzXo0lXDP0bzyy5NxWkpE= sven@phalanx"
export PUBKEY_ONLY_SSH=1

export STAGE_LIST="stage0 stage1 stage2 stage3 stage4 stage_zaf"
#export STAGE_LIST="stage0 stage1 stage2"

./build.sh
