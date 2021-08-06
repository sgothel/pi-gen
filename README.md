# pi-gen

Tool used to create Debian and Raspberry Pi derived OS images.


## Dependencies

pi-gen has been tested and runs on Debian 11 `Bullseye` 
to produce OS images for Raspi-arm64, Raspi-armhf and PC-amd64 machines
based on Debian 10 `Buster` and Debian 11 `Bullseye`. 

PC-i386 is also supported, however, it has not been tested lately.

Related config variables are 
* `TARGET_RASPI`
* `TARGET_ARCH`
* `RELEASE`

It might be possible to use Docker on other Linux distributions as described below,
however, I have not tested this procedure.

To install the required dependencies for `pi-gen` you should run:

```bash
apt-get install coreutils quilt parted qemu-user-static debootstrap zerofree zip \
dosfstools libarchive-tools libcap2-bin grep rsync xz-utils file git curl bc \
qemu-utils kpartx squashfs-tools fatattr
```

The file `depends` contains a list of tools needed.  The format of this
package is `<tool>[:<debian-package>]`.

### Package Source
For all targets, default source for `debootstrap` and `apt` package management
is `debian.org`.

See `PREFER_RASPI_SOURCE` below, describing how to use `raspberrypi.org`
as the package source.

## Notes

* Implementation uses qcow2

    Instead of using traditional way of building the rootfs of every stage in
    single subdirectories and copying over the previous one to the next one,
    qcow2 based virtual disks with backing images are used in every stage.
    This speeds up the build process and reduces overall space consumption
    significantly.

    <u>Optional parameters regarding qcow2 build: `BASE_QCOW2_SIZE`</u>

    **CAUTION:**  Although the qcow2 build mechanism will run fine inside Docker, it can happen
    that the network block device is not disconnected correctly after the Docker process has
    ended abnormally. In that case see [Disconnect an image if something went wrong](#Disconnect-an-image-if-something-went-wrong)

## Config

Upon execution, `build.sh` will source the optional given config file, e.g.:

```bash
    build.sh -c myconfig.cfg
```
The given config file is a bash shell fragment, intended to set needed environment variables.

It is also possible to use default values for all or most variables, e.g.:

```bash
    IMG_NAME='Raspbian' build.sh
```

The following environment variables are supported:

 * `IMG_NAME` **required** (Default: unset)

   The name of the image to build with the current stage directories.  Setting
   `IMG_NAME=Raspbian` is logical for an unmodified RPi-Distro/pi-gen build,
   but you should use something else for a customized version.  Export files
   in stages may add suffixes to `IMG_NAME`.

 * `TARGET_RASPI` (Default: `1`)

   If set to `0` (or other than `1`), the `Raspbian` `apt` source 
   and its packages are **not** being used, i.e. ending up with a vanilla `Debian` installation.

   Further `Raspberry` specific tasks are **not** performed:

     * /boot/config.txt
     * /boot/.../cmdline.txt
     * /boot/ any specific `Raspberry` bootloader
   
   **instead**, the default tasks are being used with `TARGET_RASPI=0`:

     * Install GRUB using `timeout 0` for no visible menu.

 * `TARGET_ARCH` (Default: `arm64`)

   Maybe set to any valid and supported architecture, which are 

     - arm64
     - armhf
     - i386
     - amd64

 * `RELEASE` (Default: `buster`)

   The release version to build images against. Valid values are `buster` and `bullseye`.

 * `PREFER_RASPI_SOURCE` (Default: unset)

   If set to '1' and `TARGET_RASPI=1` and `TARGET_ARCH=armhf`,
   `raspberrypi.org` will be used as the main source `debootstrap` and `apt` package management.

   Default is to use `debian.org` as the main package source for all targets.

 * `INSTALL_RECOMMENDS` (Default: unset)

   If set to one, i.e. `INSTALL_RECOMMENDS=1`, 
   installation process will install recommended packages.
   Otherwise (default):
     * apt selection without recommended and suggested

   Note: `apt cache` is disabled for all target configurations.

 * `ROOTFS_RO` (Default: unset)

   If set to one, i.e. `ROOTFS_RO=1`, the root filesystem will be set read-only,
   an `initramfs` is used to load it via `loopfs` 
   and a transient `tmpfs` created at boot containing the `overlayfs` mutable storage for
   ```
   /etc
   /home
   /var
   /srv
   /root
   ```

   Further all `apt-daily` systemd tasks are disabled,
   the ssh host keys are retained while `regenerate_ssh_host_keys` is disabled
   and the final `/boot/config.txt` has `splash` disabled (no rainbow).
   
 * `ROOTFS_RO_OVERLAY_TMPFS_SIZE` (Default: 128M)

   If using `ROOTFS_RO`, this variable specifies the shared `tmpfs` size
   for the overlays - see above.

 * `BOOT_FSTYPE` (Default: `vfat`)

   Allows user to define the `/boot` filesystem type. For Raspberry this **must** be `vfat`, the default.
   However, as we support other target system, this may be one of: `vfat`, `ext2`, `ext4` or `xfs`.

 * `BOOT_FSOPTIONS` (Default: `rw,noatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,errors=remount-ro`)

   Allows user to define the mount options for the `/boot` filesystem, see `BOOT_FSTYPE`.
   For `vfat`, only the `codepage 437` is being hardcoded in the `initrd` `loop_rootfs` and scripts, as it is the default for GNU/Linux.

   Further more, producing the image failed with `codepage 850` on `vfat` operations on the `overlay` diversions within `pi-gen`.

 * `REDUCED_FOOTPRINT` (Default: unset)

   If set to one, i.e. `REDUCED_FOOTPRINT=1`, 
   installation will attempt to keep the footprint as small as possible.
   This is intended for small devices, perhaps in addition to `ROOTFS_RO=1`.
   The following efforts are made:
     * apt selection without recommended and suggested
     * [Reduced Disk Footprint (Ubuntu)](https://wiki.ubuntu.com/ReducingDiskFootprint#Documentation) for 
       most `/usr/share/doc` and most `locale`s but [ `en*`, `da*`, `de*`, `es*`, `fi*`, `fr*`, `is*`, `nb*`, `ru*`, `sv*`, `zh*` ],
       i.e. includes [`locale`](https://www.localeplanet.com/icu/) for
         * English `en`
         * Danish `da`
         * German `de`
         * Icelandic `is`
         * Spanish `es`
         * Finnish `fi`
         * French `fr`
         * Norwegian Bokmål `nb`
         * Russia `nb`
         * Swedish `sv`
         * Chinese `zh`

    It is also **recommended** to not include *stage3b* *stage4* and *stage5* for a small embedded system,
    as they contain heavy window-manager and broader desktop applications, etc.

    See detailed notes on stages below.

   Note: `apt cache` is disabled for all target configurations.

 * `BASE_QCOW2_SIZE` (Default: 15200M)

   Size of the virtual qcow2 disk given in multiples of 1024, i.e. KiB, MiB or GiB.
   Note: it will not actually use that much of space at once but defines the
   maximum size of the virtual disk. If you change the build process by adding
   a lot of bigger packages or additional build stages, it can be necessary to
   increase the value because the virtual disk can run out of space like a normal
   hard drive would.

   Example: 16 GB sdcard:
   ```
    15962472448 B
    15588352 KiB
    15223 MiB
    14.866 GiB

    Safe: 15200 MiB
   ```

 * `APT_PROXY` (Default: unset)

   If you require the use of an apt proxy, set it here.  This proxy setting
   will not be included in the image, making it safe to use an `apt-cacher` or
   similar package for development.

   If you have Docker installed, you can set up a local apt caching proxy to
   like speed up subsequent builds like this:

       docker-compose up -d
       echo 'APT_PROXY=http://172.17.0.1:3142' >> config

 * `BASE_DIR`  (Default: location of `build.sh`)

   **CAUTION**: Currently, changing this value will probably break build.sh

   Top-level directory for `pi-gen`.  Contains stage directories, build
   scripts, and by default both work and deployment directories.

 * `WORK_DIR`  (Default: `"$BASE_DIR/work"`)

   Directory in which `pi-gen` builds the target system.  This value can be
   changed if you have a suitably large, fast storage location for stages to
   be built and cached.  Note, `WORK_DIR` stores a complete copy of the target
   system for each build stage, amounting to tens of gigabytes in the case of
   Raspbian.

   **CAUTION**: If your working directory is on an NTFS partition you probably won't be able to build: make sure this is a proper Linux filesystem.

 * `DEPLOY_DIR`  (Default: `"$BASE_DIR/deploy"`)

   Output directory for target system images and NOOBS bundles.

 * `DEPLOY_ZIP` (Default: `1`)

   Setting to `0` will deploy the actual image (`.img`) instead of a zipped image (`.zip`).

 * `USE_QEMU` (Default: `"0"`)

   Setting to '1' enables the QEMU mode - creating an image that can be mounted via QEMU for an emulated
   environment. These images include "-qemu" in the image file name.

 * `LOCALE_DEFAULT` (Default: "en_US.UTF-8" )

   Default system locale.

 * `TARGET_HOSTNAME` (Default: "raspberrypi" )

   Setting the hostname to the specified value.

 * `KEYBOARD_KEYMAP` (Default: "us" )

   Default keyboard keymap.

   To get the current value from a running system, run `debconf-show
   keyboard-configuration` and look at the
   `keyboard-configuration/xkb-keymap` value.

 * `KEYBOARD_LAYOUT` (Default: "English (US)" )

   Default keyboard layout.

   To get the current value from a running system, run `debconf-show
   keyboard-configuration` and look at the
   `keyboard-configuration/variant` value.

 * `TIMEZONE_DEFAULT` (Default: "Europe/Berlin" )

   Default keyboard layout.

   To get the current value from a running system, look in
   `/etc/timezone`.

 * `FIRST_USER_NAME` (Default: "pi" )

   Username for the first user

 * `FIRST_USER_PASS` (Default: "raspberry")

   Password for the first user

 * `WPA_ESSID`, `WPA_PASSWORD` and `WPA_COUNTRY` (Default: unset)

   If these are set, they are use to configure `wpa_supplicant.conf`, so that the Raspberry Pi can automatically connect to a wireless network on first boot. If `WPA_ESSID` is set and `WPA_PASSWORD` is unset an unprotected wireless network will be configured. If set, `WPA_PASSWORD` must be between 8 and 63 characters.

 * `ENABLE_SSH` (Default: `0`)

   Setting to `1` will enable ssh server for remote log in. Note that if you are using a common password such as the defaults there is a high risk of attackers taking over you Raspberry Pi.

 * `PUBKEY_SSH_FIRST_USER` (Default: unset)

   Setting this to a value will make that value the contents of the FIRST_USER_NAME's ~/.ssh/authorized_keys.  Obviously the value should
   therefore be a valid authorized_keys file.  Note that this does not
   automatically enable SSH.

 * `PUBKEY2_SSH_FIRST_USER` (Default: unset)

   Same as `PUBKEY_SSH_FIRST_USER`, but providing an optional second key for the first user.

 * `PUBKEY_ONLY_SSH` (Default: `0`)

   * Setting to `1` will disable password authentication for SSH and enable
   public key authentication.  Note that if SSH is not enabled this will take
   effect when SSH becomes enabled.

 * `STAGE_LIST` (Default: `stage*`)

    If set, then instead of working through the numeric stages in order, this list will be followed. For example setting to `"stage0 stage1 mystage stage2"` will run the contents of `mystage` before stage2. Note that quotes are needed around the list. An absolute or relative path can be given for stages outside the pi-gen directory.

 * `SKIP_STAGE_LIST` (default: `""`)

    Space separated list of stages, which shall not be processed, i.e. skipped.

 * `SKIP_IMAGES_LIST` (default: `""`)

    Space separated list of stages, which shall not produce file images.


## How the build process works

The following process is performed to build images:

 * Loop through all of the stage directories in alphanumeric order

 * Move on to the next directory if this stage directory basename is listed within `SKIP_STAGE_LIST`.

 * Run the script ```prerun.sh``` which is generally just used to copy the build
   directory between stages.

 * In each stage directory, loop through each subdirectory in alphanumeric order
   and then process each of the files it contains. Both, the subdirectories as well as 
   the files to be processed need to be prefixed with a two digit padded number.

   The subdirectory's files to be processed are looped through `{00..99}`,
   used as the two-digit loop index.

   If existing in the subdirectories, the following files will be processed
   in the given order during one iteration, where `nn` refers to the current two digit loop index:

     - ***nn*-debconf** - Contents of this file are passed to debconf-set-selections
       to configure things like locale, etc.

     - ***nn*-packages-sys-(raspi|debian)[-*RELEASE*]** - List of system specific packages to install.
       In case `TARGET_RASPI = "1"` (default), `nn-packages-sys-raspi` are being used, if existing.

       Otherwise `nn-packages-sys-debian` are being processed, if existing.

       If a `RELEASE` specific variant exists, e.g. `00-packages-sys-raspi-bullseye`, it will be used instead 
       of the generic `00-packages-sys-raspi`.

     - ***nn*-packages-nr[-*RELEASE*]** - A list of packages to install. Can have more than one, space
       separated, per line. Will always use ```--no-install-recommends -y``` parameters 
       for apt-get, ignoring `INSTALL_RECOMMENDS`.

       If a `RELEASE` specific variant exists, e.g. `00-packages-nr-bullseye`, it will be used instead 
       of the generic `00-packages-nr`.

     - ***nn*-packages[-*RELEASE*]** - A list of packages to install. Can have more than one, space
       separated, per line. Depending on `INSTALL_RECOMMENDS`, recommended packages will be 
       installed or not.

       If a `RELEASE` specific variant exists, e.g. `00-packages-bullseye`, it will be used instead 
       of the generic `00-packages`.

     - ***nn*-patches** - A directory containing patch files to be applied, using quilt.
       If a file named 'EDIT' is present in the directory, the build process will
       be interrupted with a bash session, allowing an opportunity to create/revise
       the patches.

     - ***nn*-run.sh** - A unix shell script. Needs to be made executable for it to run.

     - ***nn*-run-chroot.sh** - A unix shell script which will be run in the chroot
       of the image build directory. Needs to be made executable for it to run.

  * If the stage directory contains a file named `EXPORT_NOOBS` or `EXPORT_IMAGE` 
    and the stage directory basename is not listed within `SKIP_STAGE_LIST`,
    the file images for this stage will be generated.

It is recommended to examine build.sh for finer details.


## Docker Build

*Currently untested within this branch of pi-gen!*

Docker can be used to perform the build inside a container. This partially isolates
the build from the host system, and allows using the script on non-debian based
systems (e.g. Fedora Linux). The isolate is not complete due to the need to use
some kernel level services for arm emulation (binfmt) and loop devices (losetup).

To build:

```bash
vi myconfig.cfg         # Edit your config file. See above.
./build-docker.sh -c myconfig.cfg
```

If everything goes well, your finished image will be in the `deploy/` folder.
You can then remove the build container with `docker rm -v pigen_work`

If something breaks along the line, you can edit the corresponding scripts, and
continue:

```bash
CONTINUE=1 ./build-docker.sh
```

To examine the container after a failure you can enter a shell within it using:

```bash
sudo docker run -it --privileged --volumes-from=pigen_work pi-gen /bin/bash
```

After successful build, the build container is by default removed. This may be undesired when making incremental changes to a customized build. To prevent the build script from remove the container add

```bash
PRESERVE_CONTAINER=1 ./build-docker.sh
```

There is a possibility that even when running from a docker container, the
installation of `qemu-user-static` will silently fail when building the image
because `binfmt-support` _must be enabled on the underlying kernel_. An easy
fix is to ensure `binfmt-support` is installed on the host machine before
starting the `./build-docker.sh` script (or using your own docker build
solution).

### Passing arguments to Docker

When the docker image is run various required command line arguments are provided.  For example the system mounts the `/dev` directory to the `/dev` directory within the docker container.  If other arguments are required they may be specified in the PIGEN_DOCKER_OPTS environment variable.  For example setting `PIGEN_DOCKER_OPTS="--add-host foo:192.168.0.23"` will add '192.168.0.23   foo' to the `/etc/hosts` file in the container.  The `--name`
and `--privileged` options are already set by the script and should not be redefined.

## Stage Anatomy

### Build Stage Overview

The build is divided up into several stages for logical clarity
and modularity.  This causes some initial complexity, but it simplifies
maintenance and allows for more easy customization.

 - **stage0** - bootstrap.  The primary purpose of this stage is to create a
   usable filesystem.  This is accomplished largely through the use of
   `debootstrap`, which creates a minimal filesystem suitable for use as a
   base.tgz on Debian systems.  This stage also configures apt settings and
   installs `raspberrypi-bootloader` which is missed by debootstrap.  The
   minimal core is installed but not configured, and the system will not quite
   boot yet.

 - **stage1** - truly minimal system.  This stage makes the system bootable by
   installing system files like `/etc/fstab`, configures the bootloader, makes
   the network operable, and installs packages like raspi-config.  At this
   stage the system should boot to a local console from which you have the
   means to perform basic tasks needed to configure and install the system.
   This is as minimal as a system can possibly get, and its arguably not
   really usable yet in a traditional sense yet.  Still, if you want minimal,
   this is minimal and the rest you could reasonably do yourself as sysadmin.

 - **stage2** - `lite system`.  This stage produces the `Lite image`.  It
   installs some optimized memory functions, sets timezone and charmap
   defaults, installs fake-hwclock and ntp, wireless LAN and bluetooth support,
   dphys-swapfile, and other basics for managing the hardware.  It also
   creates necessary groups and gives the pi user access to sudo and the
   standard console hardware permission groups.

   Python and Lua are included here, as they are often required by certain setup scripts.

 - **stage3a** - `litex system`. Contains a minimal *xserver-xorg* subset and *dwm* with *stterm*,
    suitable for embedded systems using graphics.

 - **stage3a_dev** - `litexdev system`. Contains full commandline development tools
   and developer library packages based on *stage3a* inclusive *build-essential*, gcc, clang, OpenJDK 11, etc.

 - **stage3b_lxde** - `lxde desktop system`. Contains a complete desktop system
   with X11, LXDE and a web browser. Suitable for `ROOTFS_RO`.

 - **stage3b_kde** - `kde desktop system`. Contains a complete desktop system
   with X11, KDE Plasma and a web browser. Not yet working well with `ROOTFS_RO`.

 - **stage4** - `Python image`. System meant to fit on a 4GB card. This is the
   stage that installs most things to be friendly to new
   users like system documentation and most of `python`.

 - **stage5** - Full image. More development
   tools, an email client, learning tools like Scratch, specialized packages
   like sonic-pi, office productivity, etc.  

 - **stage_rescue** - `rescue desktop system`. Adds rescue related tools to desktop system,
   best suited ontop of *stage3b_lxde* for `ROOTFS_RO` to produce a *rescue stick*.

   If `TARGET_RASPI != 1`, i.e. using a `Debian` system, `memtest86+` is added to `GRUB`,
   which menu made visible again using `timeout 5`.

### Stage specification

If you wish to build up to a specified stage (such as building up to `stage2`
for a lite system), include the stage directory basename in space separated variable `SKIP_STAGE_LIST`.

If you wish to not build the file images of a stage, 
include the stage directory basename in space separated variable `SKIP_IMAGES_LIST`.

```bash
# Example for building a lite system
echo "IMG_NAME='Raspbian'" > myconfig.cfg
echo "SKIP_STAGE_LIST='stage3 stage4 stage5'" >> myconfig.cfg
echo "SKIP_IMAGES_LIST='stage4 stage5'" >> myconfig.cfg
sudo ./build.sh -c myconfig.cfg  # or ./build-docker.sh -c myconfig.cfg
```

If you wish to build further configurations upon (for example) the lite
system, you can create your own custom stages and specify `STAGE_LIST` accordingly.


## Skipping stages to speed up development

If you're working on a specific stage the recommended development process is as
follows, assuming using `myconfig.cfg` for configuration:

 * Skip image production for all stages but your build target stage: 
   Add stage basenames to space separated variable `SKIP_IMAGES_LIST` in `myconfig.cfg`.
 * Run `sudo build.sh -c myconfig.cfg` to build all stages
 * Skip whole stages passed: Add stage basenames to space separated variable `SKIP_STAGE_LIST` in `myconfig.cfg`.
 * Modify the last stage
 * Rebuild just the last stage using `sudo ./build.sh -c myconfig.cfg`
 * Once you're happy with the image you can uncomment the `SKIP_STAGE_LIST` in your `myconfig.cfg` and
   export your image to test

# Regarding Qcow2 image building

### Get infos about the image in use

If you issue the two commands shown in the example below in a second command shell while a build
is running you can find out, which network block device is currently being used and which qcow2 image
is bound to it.

Example:

```bash
root@build-machine:~/$ lsblk | grep nbd
nbd1      43:32   0    10G  0 disk 
├─nbd1p1  43:33   0    10G  0 part 
└─nbd1p1 253:0    0    10G  0 part

root@build-machine:~/$ ps xa | grep qemu-nbd
 2392 pts/6    S+     0:00 grep --color=auto qemu-nbd
31294 ?        Ssl    0:12 qemu-nbd --discard=unmap -c /dev/nbd1 image-stage4.qcow2
```

Here you can see, that the qcow2 image `image-stage4.qcow2` is currently connected to `/dev/nbd1` with
the associated partition map `/dev/mapper/nbd1p1`. Don't worry that `lsblk` shows two entries. It is totally fine, because the device map is accessible via `/dev/mapper/nbd1p1` and also via `/dev/dm-0`. This is all part of the device mapper functionality of the kernel. See `dmsetup` for further information.

### Mount a qcow2 image

If you want to examine the content of a a single stage, you can simply mount the qcow2 image found in the `WORK_DIR` directory with the tool `./imagetool.sh`.

See `./imagetool.sh -h` for further details on how to use it.

### Disconnect an image if something went wrong

It can happen, that your build stops in case of an error. Normally `./build.sh` should handle image disconnection appropriately, but in rare cases, especially during a Docker build, this may not work as expected. If that happens, starting a new build will fail and you may have to disconnect the image and/or device yourself.

A typical message indicating that there are some orphaned device mapper entries is this:

```
Failed to set NBD socket 
Disconnect client, due to: Unexpected end-of-file before all bytes were read
```

If that happens go through the following steps:

1. First, check if the image is somehow mounted to a directory entry and umount it as you would any other block device, like i.e. a hard disk or USB stick.

2. Second, to disconnect an image from `qemu-nbd`, the QEMU Disk Network Block Device Server, issue the following command (be sure to change the device name to the one actually used):

   ```bash
   sudo qemu-nbd -d /dev/nbd1
   ```

   Note: if you use Docker build, normally no active `qemu-nbd` process exists anymore as it will be terminated when the Docker container stops.

3. To disconnect a device partition map from the network block device, execute:

   ```bash
   sudo kpartx -d /dev/nbd1
   or
   sudo ./imagetool.sh --cleanup
   ```
   
   Note: The `imagetool.sh` command will cleanup any /dev/nbdX that is not connected to a running `qemu-nbd` daemon. Be careful if you use network block devices for other tasks utilizing NBDs on your build machine as well.

Now you should be able to start a new build without running into troubles again. Most of the time, especially when using Docker build, you will only need no. 3 to get everything up and running again. 

# Troubleshooting

## `64 Bit Systems`
Please note there is currently an issue when compiling with a 64 Bit OS. See https://github.com/RPi-Distro/pi-gen/issues/271

## `binfmt_misc`

Linux is able execute binaries from other architectures, meaning that it should be
possible to make use of `pi-gen` on an x86_64 system, even though it will be running
ARM binaries. This requires support from the [`binfmt_misc`](https://en.wikipedia.org/wiki/Binfmt_misc)
kernel module.

You may see the following error:

```
update-binfmts: warning: Couldn't load the binfmt_misc module.
```

To resolve this, ensure that the following files are available (install them if necessary):

```
/lib/modules/$(uname -r)/kernel/fs/binfmt_misc.ko
/usr/bin/qemu-arm-static
```

You may also need to load the module by hand - run `modprobe binfmt_misc`.
