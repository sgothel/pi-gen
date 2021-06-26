8 GB SD Image-A (intermediate):
* boot 250MB (rw, vfat)
* data 1GB (rw, ext4): fixed size, [overlayfs](https://www.kernel.org/doc/html/latest/filesystems/overlayfs.html?highlight=overlayfs) data [/etc /home /srv /tmp /var]
* rootfs 3.0GB (ext4, no-journal, read-only)

16GB SD Image-B (final):
* boot 250MB (rw, vfat): just boot
* data 1GB (rw, ext4): fixed size, [overlayfs](https://www.kernel.org/doc/html/latest/filesystems/overlayfs.html?highlight=overlayfs) data [/etc /home /srv /tmp /var]
* system 14GB (rw, vfat): app-data, app-image [current, old], rootfs-image [current, old]

+++

The `block` filesystems:
```
/dev/mmcblk0p3 on / type ext4 (ro,noatime,errors=remount-ro)
/dev/mmcblk0p2 on /data type ext4 (rw,noatime)
overlay on /etc type overlay (rw,noatime,lowerdir=/etc,upperdir=/data/etc/upper,workdir=/data/etc/work)
overlay on /home type overlay (rw,noatime,lowerdir=/home,upperdir=/data/home/upper,workdir=/data/home/work)
overlay on /srv type overlay (rw,noatime,lowerdir=/srv,upperdir=/data/srv/upper,workdir=/data/srv/work)
overlay on /tmp type overlay (rw,noatime,lowerdir=/tmp,upperdir=/data/tmp/upper,workdir=/data/tmp/work)
overlay on /var type overlay (rw,noatime,lowerdir=/var,upperdir=/data/var/upper,workdir=/data/var/work)
/dev/mmcblk0p1 on /boot type vfat (rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,errors=remount-ro)
```

The `tempfs` filesystems:
```
devtmpfs on /dev type devtmpfs (rw,relatime,size=333136k,nr_inodes=83284,mode=755)
tmpfs on /dev/shm type tmpfs (rw,nosuid,nodev)
tmpfs on /run type tmpfs (rw,nosuid,nodev,mode=755)
tmpfs on /run/lock type tmpfs (rw,nosuid,nodev,noexec,relatime,size=5120k)
tmpfs on /sys/fs/cgroup type tmpfs (ro,nosuid,nodev,noexec,mode=755)
tmpfs on /etc/machine-id type tmpfs (ro,mode=755)
tmpfs on /run/user/1000 type tmpfs (rw,nosuid,nodev,relatime,size=93204k,mode=700,uid=1000,gid=1000)
```

The `special` filesystems:
```
sysfs on /sys type sysfs (rw,nosuid,nodev,noexec,relatime)
proc on /proc type proc (rw,relatime)
securityfs on /sys/kernel/security type securityfs (rw,nosuid,nodev,noexec,relatime)
devpts on /dev/pts type devpts (rw,nosuid,noexec,relatime,gid=5,mode=620,ptmxmode=000)
cgroup2 on /sys/fs/cgroup/unified type cgroup2 (rw,nosuid,nodev,noexec,relatime,nsdelegate)
cgroup on /sys/fs/cgroup/systemd type cgroup (rw,nosuid,nodev,noexec,relatime,xattr,name=systemd)
none on /sys/fs/bpf type bpf (rw,nosuid,nodev,noexec,relatime,mode=700)
cgroup on /sys/fs/cgroup/net_cls,net_prio type cgroup (rw,nosuid,nodev,noexec,relatime,net_cls,net_prio)
cgroup on /sys/fs/cgroup/cpu,cpuacct type cgroup (rw,nosuid,nodev,noexec,relatime,cpu,cpuacct)
cgroup on /sys/fs/cgroup/cpuset type cgroup (rw,nosuid,nodev,noexec,relatime,cpuset)
cgroup on /sys/fs/cgroup/freezer type cgroup (rw,nosuid,nodev,noexec,relatime,freezer)
cgroup on /sys/fs/cgroup/devices type cgroup (rw,nosuid,nodev,noexec,relatime,devices)
cgroup on /sys/fs/cgroup/pids type cgroup (rw,nosuid,nodev,noexec,relatime,pids)
cgroup on /sys/fs/cgroup/blkio type cgroup (rw,nosuid,nodev,noexec,relatime,blkio)
cgroup on /sys/fs/cgroup/perf_event type cgroup (rw,nosuid,nodev,noexec,relatime,perf_event)
systemd-1 on /proc/sys/fs/binfmt_misc type autofs (rw,relatime,fd=29,pgrp=1,timeout=0,minproto=5,maxproto=5,direct)
mqueue on /dev/mqueue type mqueue (rw,relatime)
debugfs on /sys/kernel/debug type debugfs (rw,relatime)
sunrpc on /run/rpc_pipefs type rpc_pipefs (rw,relatime)
configfs on /sys/kernel/config type configfs (rw,relatime)
```
