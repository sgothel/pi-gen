#!/bin/bash

#zfs set aclinherit=passthrough $POOL
#zfs set acltype=posixacl $POOL
#zfs set xattr=sa $POOL

setfacl -d --set u::rwx,g::rwx,o::r-x /data 
setfacl -d --set u::rwx,g::r-x,o::r-x /usr/local/projects
setfacl -d --set u::rwx,g::rwx,o::r-x /srv
setfacl -d --set u::rwx,g::r-x,o::--- /backup
setfacl -d --set u::rwx,g::r-x,o::--- /home
setfacl -d --set u::rwx,g::r-x,o::--- /root

