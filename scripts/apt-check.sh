#!/bin/bash

#set -x

sdir=`dirname $(readlink -f "${BASH_SOURCE[0]}")`
rootdir=`dirname $sdir`

packfile=$1

echo "Testing packages in ${packfile}"
PACKAGES=$(sed -f "${sdir}/remove-comments.sed" < "${packfile}")

for i in ${PACKAGES} ; do 
    if ! apt-cache show ${i} > /dev/null 2>&1 ; then 
        echo missing ${i} 
    else 
        echo exists ${i} 
    fi 
done
