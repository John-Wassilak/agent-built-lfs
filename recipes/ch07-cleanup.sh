#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter07/cleanup.html
# title  : 7.13. Cleaning up and Saving the Temporary System
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: 7.13.1. Cleaning First, remove the currently installed documentation files to prevent
#   ctx: them from ending up in the final system, and to save about 35 MB:
rm -rf /usr/share/{info,man,doc}/*

# --- block 1 --------------------------------------------------
#   ctx: Second, on a modern Linux system, the libtool .la files are only useful for libltdl. No
#   ctx: libraries in LFS are loaded by libltdl, and it's known that some .la files can cause
#   ctx: BLFS package failures. Remove those files now:
find /usr/{lib,libexec} -name \*.la -delete

# --- block 2 --------------------------------------------------
#   ctx: The current system size is now about 3 GB, however the /tools directory is no longer
#   ctx: needed. It uses about 1 GB of disk space. Delete it now:
rm -rf /tools

# --- block 3 --------------------------------------------------
#   ctx: . The following steps are performed from outside the chroot environment. That means you
#   ctx: have to leave the chroot environment first before continuing. The reason for that is to
#   ctx: get access to file system locations outside of the chroot environment to store/read the
#   ctx: backup archive, which ought not be placed within the $LFS hierarchy. If you have decided
#   ctx: to make a backup, leave the chroot environment:
#   REVIEWED [drop]: Book tells a human reader to leave the chroot. As a script line, 'exit' would end the step early and silently skip anything after it.
# exit

# --- block 4 --------------------------------------------------
#   ctx: he commands you're going to run as mistakes made here can modify your host system. Be
#   ctx: aware that the environment variable LFS is set for user lfs by default but may not be
#   ctx: set for root. Whenever commands are to be executed by root, make sure you have set LFS.
#   ctx: This has been discussed in Section 2.6, “Setting the $LFS Variable and the Umask.”
#   ctx: Before making a backup, unmount the virtual file systems:
#   REVIEWED [drop]: Part of the book's OPTIONAL backup procedure and runs on the HOST, not in the chroot. Unmounting is handled by bin/lfs-umount when we choose to.
# mountpoint -q $LFS/dev/shm && umount $LFS/dev/shm
# umount $LFS/dev/pts
# umount $LFS/{sys,proc,run,dev}

# --- block 5 --------------------------------------------------
#   ctx: me directory of the host system's root user, which is typically found on the root file
#   ctx: system. Replace $HOME by a directory of your choice if you do not want to have the
#   ctx: backup stored in root's home directory. Create the backup archive by running the
#   ctx: following command: Note Because the backup archive is compressed, it takes a relatively
#   ctx: long time (over 10 minutes) even on a reasonably fast system.
#   REVIEWED [drop]: Book's OPTIONAL temp-system backup tarball, also host-side. We take equivalent checkpoints with bin/lfs-archive, which additionally preserves xattrs/ACLs and runs a leak check.
# cd $LFS
# tar -cJpf $HOME/lfs-temp-tools-13.0-systemd.tar.xz .

