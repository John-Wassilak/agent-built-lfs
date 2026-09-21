#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/general/libpng.html
# title  : libpng-1.6.58
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: BU (with tests) Additional Downloads Recommended patch to include animated png
#   ctx: functionality in libpng (required to use the system libpng in Firefox, Seamonkey, and
#   ctx: Thunderbird):
#   ctx: https://downloads.sourceforge.net/sourceforge/libpng-apng/libpng-1.6.58-apng.patch.gz
#   ctx: Patch md5sum: 1eef1ddd6def88814d1a65ce1f4dceb9 Installation of libpng If you want to
#   ctx: patch libpng to support apng files, apply it here:
zcat ../libpng-1.6.58-apng.patch.gz | patch -p1

# --- block 1 --------------------------------------------------
#   ctx: Install libpng by running the following commands:
./configure --prefix=/usr --disable-static &&
make

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user:
make install &&
install -vDm644 README libpng-manual.txt -t /usr/share/doc/libpng-1.6.58

