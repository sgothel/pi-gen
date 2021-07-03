#!/bin/sh

sdir=`dirname $(readlink -f $0)`
rootdir=`dirname $sdir`

touch ${rootdir}/stage0/SKIP
touch ${rootdir}/stage1/SKIP
touch ${rootdir}/stage3/SKIP
touch ${rootdir}/stage4/SKIP
touch ${rootdir}/stage5/SKIP
touch ${rootdir}/stage_zaf/SKIP

touch ${rootdir}/stage2/SKIP_IMAGES
touch ${rootdir}/stage4/SKIP_IMAGES

echo SKIP
find ${rootdir} -name SKIP

echo SKIP_IMAGES
find ${rootdir} -name SKIP_IMAGES
