#!/bin/sh

sdir=`dirname $(readlink -f $0)`
rootdir=`dirname $sdir`

rm -f ${rootdir}/stage0/SKIP
rm -f ${rootdir}/stage1/SKIP
rm -f ${rootdir}/stage3/SKIP
rm -f ${rootdir}/stage4/SKIP
rm -f ${rootdir}/stage5/SKIP
rm -f ${rootdir}/stage_zaf/SKIP

rm -f ${rootdir}/stage2/SKIP_IMAGES
rm -f ${rootdir}/stage4/SKIP_IMAGES

echo SKIP
find ${rootdir} -name SKIP

echo SKIP_IMAGES
find ${rootdir} -name SKIP_IMAGES
