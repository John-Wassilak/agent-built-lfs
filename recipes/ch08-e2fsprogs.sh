#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/e2fsprogs.html
# title  : 8.83. E2fsprogs-1.47.3
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The E2fsprogs package contains the utilities for handling the ext2 file system. It also
#   ctx: supports the ext3 and ext4 journaling file systems. Approximate build time: 2.4 SBU on a
#   ctx: spinning disk, 0.4 SBU on an SSD Required disk space: 100 MB 8.83.1. Installation of
#   ctx: E2fsprogs The E2fsprogs documentation recommends that the package be built in a
#   ctx: subdirectory of the source tree:
mkdir -v build
cd       build

# --- block 1 --------------------------------------------------
#   ctx: Prepare E2fsprogs for compilation:
../configure --prefix=/usr       \
             --sysconfdir=/etc   \
             --enable-elf-shlibs \
             --disable-libblkid  \
             --disable-libuuid   \
             --disable-uuidd     \
             --disable-fsck

# --- block 2 --------------------------------------------------
#   ctx: The meaning of the configure options: --enable-elf-shlibs This creates the shared
#   ctx: libraries which some programs in this package use. --disable-* These prevent building
#   ctx: and installing the libuuid and libblkid libraries, the uuidd daemon, and the fsck
#   ctx: wrapper; util-linux installs more recent versions. Compile the package:
make

# --- block 3 --------------------------------------------------
#   ctx: To run the tests, issue:
#   TAGS: testsuite   [DISABLED - review]
# make check

# --- block 4 --------------------------------------------------
#   ctx: One test named m_assume_storage_prezeroed is known to fail. Another test named
#   ctx: m_rootdir_acl is known to fail if the file system used for the LFS system is not ext4.
#   ctx: Install the package:
make install

# --- block 5 --------------------------------------------------
#   ctx: Remove useless static libraries:
rm -fv /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a

# --- block 6 --------------------------------------------------
#   ctx: This package installs a gzipped .info file but doesn't update the system-wide dir file.
#   ctx: Unzip this file and then update the system dir file using the following commands:
gunzip -v /usr/share/info/libext2fs.info.gz
install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info

# --- block 7 --------------------------------------------------
#   ctx: If desired, create and install some additional documentation by issuing the following
#   ctx: commands:
makeinfo -o      doc/com_err.info ../lib/et/com_err.texinfo
install -v -m644 doc/com_err.info /usr/share/info
install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info

# --- block 8 --------------------------------------------------
#   ctx: progs /etc/mke2fs.conf contains the default value of various command line options of
#   ctx: mke2fs. You may edit the file to make the default values suitable for your needs. For
#   ctx: example, some utilities (not in LFS or BLFS) cannot recognize a ext4 file system with
#   ctx: metadata_csum_seed feature enabled. If you need such a utility, you may remove the
#   ctx: feature from the default ext4 feature list with the command:
sed 's/metadata_csum_seed,//' -i /etc/mke2fs.conf

