#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/util-linux.html
# title  : 8.82. Util-linux-2.41.3
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Util-linux package contains miscellaneous utility programs. Among them are utilities
#   ctx: for handling file systems, consoles, partitions, and messages. Approximate build time:
#   ctx: 0.5 SBU Required disk space: 346 MB 8.82.1. Installation of Util-linux Prepare
#   ctx: Util-linux for compilation:
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
            --docdir=/usr/share/doc/util-linux-2.41.3

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
#   ctx: k tests will fail if the host's kernel does not have the option
#   ctx: CONFIG_CRYPTO_USER_API_HASH enabled or does not have any options providing a SHA256
#   ctx: implementation (for example, CONFIG_CRYPTO_SHA256, or CONFIG_CRYPTO_SHA256_SSSE3 if the
#   ctx: CPU supports Supplemental SSE3) enabled. In addition, the lsfd: inotify test will fail
#   ctx: if the kernel option CONFIG_NETLINK_DIAG is not enabled. Install the package:
make install

