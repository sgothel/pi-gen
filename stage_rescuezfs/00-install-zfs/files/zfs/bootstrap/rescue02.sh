#!/bin/bash

export BASE_DIR=`dirname $(readlink -f "${BASH_SOURCE[0]}")`

source "${BASE_DIR}/rescue00.sh"

source "${BASE_DIR}/common.sh"

on_chroot -c "bash --login"

