#!/bin/sh

zfs list -o name,used,avail,refer,compression,recordsize,mountpoint $*

