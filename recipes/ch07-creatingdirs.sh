#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter07/creatingdirs.html
# title  : 7.5. Creating Directories
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: time to create the full directory structure in the LFS file system. Note Some of the
#   ctx: directories mentioned in this section may have already been created earlier with
#   ctx: explicit instructions, or when installing some packages. They are repeated below for
#   ctx: completeness. Create some root-level directories that are not in the limited set
#   ctx: required in the previous chapters by issuing the following command:
mkdir -pv /{boot,home,mnt,opt,srv}

# --- block 1 --------------------------------------------------
#   ctx: Create the required set of subdirectories below the root-level by issuing the following
#   ctx: commands:
mkdir -pv /etc/{opt,sysconfig}
mkdir -pv /lib/firmware
mkdir -pv /media/{floppy,cdrom}
mkdir -pv /usr/{,local/}{include,src}
mkdir -pv /usr/lib/locale
mkdir -pv /usr/local/{bin,lib,sbin}
mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -pv /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -pv /usr/{,local/}share/man/man{1..8}
mkdir -pv /var/{cache,local,log,mail,opt,spool}
mkdir -pv /var/lib/{color,misc,locate}

ln -sfv /run /var/run
ln -sfv /run/lock /var/lock

install -dv -m 0750 /root
install -dv -m 1777 /tmp /var/tmp

