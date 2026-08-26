#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/postlfs/lvm2.html
# title  : LVM2-2.03.38
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: Installation of LVM2 Install LVM2 by running the following commands:
PATH+=:/usr/sbin                \
./configure --prefix=/usr       \
            --enable-cmdlib     \
            --enable-pkgconfig  \
            --enable-udev_sync  &&
make

# --- block 1 --------------------------------------------------
#   ctx: The tests use udev for logical volume synchronization, so the LVM udev rules and some
#   ctx: utilities need to be installed before running the tests. If you are installing LVM2 for
#   ctx: the first time, and do not want to install the full package before running the tests,
#   ctx: the minimal set of utilities can be installed by running the following instructions as
#   ctx: the root user:
#   REVIEWED [drop]: Installs a minimal tool subset specifically so the test suite can run without a full install first ('if you do not want to install the full package before running the tests') -- block 5 does the full install regardless and tests are not being run.
# make -C tools install_tools_dynamic &&
# make -C udev  install               &&
# make -C libdm install

# --- block 2 --------------------------------------------------
#   ctx: The tests need the ability to create and remove device nodes in the /tmp directory. On
#   ctx: systemd systems, the default is to mount /tmp with the nodev option. Rather than
#   ctx: disabling this behavior permanently (since it does have valid security reasons to be
#   ctx: doing this), remount the /tmp filesystem temporarily as the root user:
#   REVIEWED [drop]: 'mount -o remount,dev /tmp' -- test-suite prep (needs device nodes in /tmp for the tests). Not running the test suite.
# mount -o remount,dev /tmp

# --- block 3 --------------------------------------------------
#   ctx: To test the results, issue, as the root user:
#   REVIEWED [drop]: 'make check_local' -- the test suite itself, needs en_US.UTF-8 locale generated. Skipped, matches every other package in this build.
# LC_ALL=en_US.UTF-8 make check_local

# --- block 4 --------------------------------------------------
#   ctx: el options are missing. For example, the lack of the dm-delay device mapper target
#   ctx: explains some failures. Some tests may fail if there is insufficient free space
#   ctx: available in the partition with the /tmp directory. At least one test fails if 16 TB is
#   ctx: not available. Some tests are flagged “warned” if thin-provisioning-tools are not
#   ctx: installed. A workaround is to add the following flags to configure:
#   REVIEWED [drop]: Orphaned continuation lines (--with-thin-check= etc), not a standalone command -- the extractor split this off from a configure invocation shown elsewhere on the page for a variant install. Not executable as its own block.
#      --with-thin-check=    \
#      --with-thin-dump=     \
#      --with-thin-repair=   \
#      --with-thin-restore=  \
#      --with-cache-check=   \
#      --with-cache-dump=    \
#      --with-cache-repair=  \
#      --with-cache-restore= \

# --- block 5 --------------------------------------------------
#   ctx: ry, for example: rm test/shell/lvconvert-raid-reshape.sh. The tests generate a lot of
#   ctx: kernel messages, which may clutter your terminal. You can disable them by issuing dmesg
#   ctx: -D before running the tests (do not forget to issue dmesg -E when tests are done). Note
#   ctx: The checks create device nodes in the /tmp directory. The tests will fail if /tmp is
#   ctx: mounted with the nodev option. Now, as the root user:
make install
make install_systemd_units

# --- block 6 --------------------------------------------------
#   ctx: les building of the Device Mapper event daemon. make install_systemd_units: This is
#   ctx: needed to install a unit that activates logical volumes at boot. It is not installed by
#   ctx: default. Configuring LVM2 Config File /etc/lvm/lvm.conf Configuration Information The
#   ctx: default configuration still references the obsolete /var/lock directory. This creates a
#   ctx: deadlock at boot time. Change this (as the root user):
sed -e '/locking_dir =/{s/#//;s/var/run/}' \
    -i /etc/lvm/lvm.conf

