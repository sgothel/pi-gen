#!/bin/sh

poolname=$1
shift
snapname=$1
shift

if [ -z "$poolname" -o -z "$snapname" ] ; then
    echo "Usage: $0 <pool-name> <snapname_to_be_destroyed>"
    exit 0
fi

zfs list -t snapshot -H -o name -r ${poolname} | grep "@${snapname}" | xargs -n1 zfs destroy
