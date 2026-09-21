#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter07/kernfs.html
# title  : 7.3. Preparing Virtual Kernel File Systems
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: file systems created by the kernel to communicate with the kernel itself. These file
#   ctx: systems are virtual: no disk space is used for them. The content of these file systems
#   ctx: resides in memory. These file systems must be mounted in the $LFS directory tree so the
#   ctx: applications can find them in the chroot environment. Begin by creating the directories
#   ctx: on which these virtual file systems will be mounted:
mkdir -pv $LFS/{dev,proc,sys,run}

# --- block 1 --------------------------------------------------
#   ctx: populate it. But some host kernels lack devtmpfs support; these host distros use
#   ctx: different methods to create the content of /dev. So the only host-agnostic way to
#   ctx: populate the $LFS/dev directory is by bind mounting the host system's /dev directory. A
#   ctx: bind mount is a special type of mount that makes a directory subtree or a file visible
#   ctx: at some other location. Use the following command to do this.
mount -v --bind /dev $LFS/dev

# --- block 2 --------------------------------------------------
#   ctx: 7.3.2. Mounting Virtual Kernel File Systems Now mount the remaining virtual kernel file
#   ctx: systems:
mount -vt devpts devpts -o gid=5,mode=0620 $LFS/dev/pts
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys
mount -vt tmpfs tmpfs $LFS/run

# --- block 3 --------------------------------------------------
#   ctx: s, /dev/shm is a symbolic link to a directory, typically /run/shm. The /run tmpfs was
#   ctx: mounted above so in this case only a directory needs to be created with the correct
#   ctx: permissions. In other host systems /dev/shm is a mount point for a tmpfs. In that case
#   ctx: the mount of /dev above will only create /dev/shm as a directory in the chroot
#   ctx: environment. In this situation we must explicitly mount a tmpfs:
if [ -h $LFS/dev/shm ]; then
  install -v -d -m 1777 $LFS$(realpath /dev/shm)
else
  mount -vt tmpfs -o nosuid,nodev tmpfs $LFS/dev/shm
fi

