# Stateless Multiboot System

The following stateless multiboot system exposes the following attributes

* Using a readonly rootfs system
* If files are mutated in a running system, allow capability to reset to default
* Organize self containing system folder: kernel, rootfs, config.txt, ..
* Host multiple system folders: `/boot/sys_arm64_[000-999]/`
* Host one immutable factory default folder `/boot/sys_arm64_000/`
* Fallback mechanism to last known system or factor default system.

## SD Card Requirement: 15200 MiB

Example: 16 GB sdcard:

```
    15962472448 B
    15588352 KiB
    15223 MiB
    14.866 GiB

    Safe: 15200 MiB
```

## Filesystem Layout

**16 GB SD Image-A (15223 MiB, full vfat):**

* x: mbr      4 MiB
* 1: boot 15200 MiB (rw, vfat): boot, system folder, app-data, app-image [current, old]

```
/boot
/boot/bootcode.bin
/boot/config.txt: 'Contains system switch os_prefix=sys_arm64_000/'
/boot/fix*.dat
/boot/start*.elf

/boot/config.bak: Old config.txt used before update or fallback.

                  The following 2 files shall be deleted after successful update
/boot/sys_last    Holds previous os_prefix before attempting to boot a new update
/boot/sys_cntr    Holds boot counter of update. If 1 at boot, fallback to previous os_prefix.

/boot/sys_arm64_000               sys_arm64_000 is immutable factory default
/boot/sys_arm64_000/bcm*.dbt
/boot/sys_arm64_000/cmdline.txt   root=file -> /boot/${os_prefix}/rootfs.img loop_rootfs mount
/boot/sys_arm64_000/config.txt    Own copy of config.txt for each system folder
/boot/sys_arm64_000/initrd.img    The loop_rootfs aware initial ramdisk loader
/boot/sys_arm64_000/issue.txt     Specification of the rootfs system
/boot/sys_arm64_000/kernel??.img  The kernel images
/boot/sys_arm64_000/overlays/
/boot/sys_arm64_000/rootfs.img    The read-only rootfs

/boot/sys_arm64_001               A new update version 001
/boot/sys_arm64_001/ .. ditto ...

/boot/sys_arm64_002               A new update version 002
/boot/sys_arm64_002/ .. ditto ...
```

## Implementation

### Update initiation by Elevator
Elevator update writes the testing new OS_PREFIX into `/boot/config.txt`
and writes the previous into `/boot/sys_last` as a fallback.

### Bootloader via initrd and `loop_rootfs`
* If `ROOT` != `file` perform normal boot operations (the `root` cmdline.txt argument)

* If `/boot/sys_last` exists, loop_rootfs will
    * If `boot/sys_cntr` doesn't exist, create it with value `1` Boot the new update.
    * If `boot/sys_cntr` exist and holds value <= 0, increment it: Boot the new update.
    * Otherwise: Fallback to `/boot/sys_last`

The fallback has been simplified to:

* copy `boot/config.txt` -> `boot/config.bak`
* copy `boot/<sys_fallback>/config.txt` -> `boot/config.txt`

In any case where the `rootfs.img` check fails,
a fallback escalation will be used:

* `/boot/sys_last` if exists, i.e. pre-update system
* `sys_arm64_000` factory default, i.e. the last resort

The following `rootfs.img` checks are performed:

* file exists
* filesystem type known
* `fsck -V -t fstype rootfs.img`

The following `boot` partition check is performed

```
while ! fsck -f -y -V -t vfat "${BOOT_PART}"; do
    panic "The vfat filesystem on ${BOOT_PART} requires a manual fsck"
done
```

### Updated System Validation

Whenever a system has been booted,
it shall determine whether it is working.

If working, it shall remove the files (if exists):
* `/boot/sys_last`
* `boot/sys_cntr`

Now the new system has been accepted.

Otherwise the system shall reboot.

A system may also initiate a fallback on its own,
by copying the desired `/boot/<sys_fallback>/config.txt` to `/boot/config.txt`.

In case the system is frozen and broken,
the user shall reset the system
which will cause aforementioned fallback procedure.

### Testing

Manual testing on developer machine performed with `stage2/01-sys-tweaks/files/initramfs/test/loop_rootfs_test`


## 
## Other Layouts

### Image-B Layout

16 GB SD Image-B (15223 MiB, no indirection, direct block access):

* x: mbr     4 MiB
* 1: boot 6100 MiB (rw, vfat): boot, app-data, app-image [current, old]
* 2: data 1000 MiB (rw, ext4): fixed size, [overlayfs](https://www.kernel.org/doc/html/latest/filesystems/overlayfs.html?highlight=overlayfs) data [/etc /home /srv /tmp /var]
* 3: rootfs-1 4000 MiB (ext4 or squashfs, no-journal, read-only) [current or old]
* 4: rootfs-2 4000 MiB (ext4 or squashfs, no-journal, read-only) [current or old]
* x: unused 96 MiB (actually 96 MiB + 23 MiB = 119 MiB)

### Image-C Layout

16 GB SD Image-C (final) (requires slower block access via underlying filesystem (loopfs), initramfs or other bootloader):

* boot 250 MB (rw, vfat): just boot
* data 1 GB (rw, ext4): fixed size, [overlayfs](https://www.kernel.org/doc/html/latest/filesystems/overlayfs.html?highlight=overlayfs) data [/etc /home /srv /tmp /var]
* system 14 GB (rw, vfat): app-data, app-image [current, old], rootfs-image [current, old]

## Notes

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
