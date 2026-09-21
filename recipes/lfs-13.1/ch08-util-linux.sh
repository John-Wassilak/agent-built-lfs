#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.1-systemd book.
# source : book/13.1/chapter08/util-linux.html
# title  : 8.81 Util-linux-2.42.2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Util-linux package contains miscellaneous utility programs. Among them are utilities
#   ctx: for handling file systems, consoles, partitions, and messages. Approximate build time:
#   ctx: 0.5 SBU Required disk space: 362 MB 8.81.1 Installation of Util-linux Prepare Util-linux
#   ctx: for compilation:
./configure --bindir=/usr/bin     \
            --libdir=/usr/lib     \
            --runstatedir=/run    \
            --sbindir=/usr/sbin   \
            --disable-chfn-chsh   \
            --disable-login       \
            --disable-nologin     \
            --disable-su          \
            --disable-setpriv     \
            --disable-runuser     \
            --disable-pylibmount  \
            --disable-liblastlog2 \
            --disable-static      \
            --without-python      \
            ADJTIME_PATH=/var/lib/hwclock/adjtime \
            --docdir=/usr/share/doc/util-linux-2.42.2

# --- block 1 --------------------------------------------------
#   ctx: The --disable and --without options prevent warnings about building components that
#   ctx: either require packages not in LFS, or are inconsistent with programs installed by other
#   ctx: packages. Compile the package:
make

# --- block 2 --------------------------------------------------
#   ctx: ng the test suite as the root user can be harmful to your system. To run it, the
#   ctx: CONFIG_SCSI_DEBUG option for the kernel must be available in the currently running
#   ctx: system and must be built as a module. Building it into the kernel will prevent booting.
#   ctx: For complete coverage, other BLFS packages must be installed. If desired, this test can
#   ctx: be run by booting into the completed LFS system and running:
#   REVIEWED [drop]: Book states this test can be run only after booting into the completed LFS system; it is not runnable in the chroot.
# bash tests/run.sh --srcdir=$PWD --builddir=$PWD

# --- block 3 --------------------------------------------------
touch /etc/fstab

# --- block 4 --------------------------------------------------
#   ctx: The lsfd: inotify test will fail if the kernel option CONFIG_NETLINK_DIAG is not
#   ctx: enabled. Install the package:
make install

