#!/bin/sh

pattern="ata-WDC"
ls /dev/disk/by-id/ | grep ${pattern}

