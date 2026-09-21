#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/cleanup.html
# title  : 8.86. Cleaning Up
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: Finally, clean up some extra files left over from running tests:
rm -rf /tmp/{*,.*}

# --- block 1 --------------------------------------------------
#   ctx: There are also several files in the /usr/lib and /usr/libexec directories with a file
#   ctx: name extension of .la. These are "libtool archive" files. On a modern Linux system the
#   ctx: libtool .la files are only useful for libltdl. No libraries in LFS are expected to be
#   ctx: loaded by libltdl, and it's known that some .la files can break BLFS package builds.
#   ctx: Remove those files now:
find /usr/lib /usr/libexec -name \*.la -delete

# --- block 2 --------------------------------------------------
#   ctx: For more information about libtool archive files, see the BLFS section "About Libtool
#   ctx: Archive (.la) files". The compiler built in Chapter 6 and Chapter 7 is still partially
#   ctx: installed and not needed anymore. Remove it with:
find /usr -depth -name $(uname -m)-lfs-linux-gnu\* | xargs rm -rf

# --- block 3 --------------------------------------------------
#   ctx: Finally, remove the temporary 'tester' user account created at the beginning of the
#   ctx: previous chapter.
userdel -r tester

