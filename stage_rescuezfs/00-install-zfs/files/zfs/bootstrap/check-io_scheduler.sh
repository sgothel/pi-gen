#! /bin/sh

for i in /sys/block/* ; do echo $i ; cat $i//queue/scheduler ; done
