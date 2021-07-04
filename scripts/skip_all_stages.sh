#!/bin/sh

sdir=`dirname $(readlink -f $0)`
rootdir=`dirname $sdir`

touch ${rootdir}/stage0/SKIP
touch ${rootdir}/stage1/SKIP
touch ${rootdir}/stage2/SKIP
touch ${rootdir}/stage3a/SKIP
touch ${rootdir}/stage3b/SKIP
touch ${rootdir}/stage4/SKIP
touch ${rootdir}/stage5/SKIP
touch ${rootdir}/stage_zaf/SKIP

touch ${rootdir}/stage2/SKIP_IMAGES
touch ${rootdir}/stage4/SKIP_IMAGES

echo SKIP Entries:
find ${rootdir} -name SKIP

echo SKIP_IMAGES Entries:
find ${rootdir} -name SKIP_IMAGES
