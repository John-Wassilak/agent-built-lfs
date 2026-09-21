#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/basicnet/libpsl.html
# title  : libpsl-0.23.3
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: B Estimated disk space required: 51 MB Estimated build time: less than 0.1 SBU
#   ctx: (including tests) libpsl Dependencies Recommended libidn2-2.3.8 and libunistring-1.4.2
#   ctx: Optional GTK-Doc-1.36.1 (for documentation), ICU-78.3 (may be used instead of libidn2),
#   ctx: libidn-1.44 (may be used instead of libidn2), Valgrind-3.27.1 (for tests) Installation
#   ctx: of libpsl Install libpsl by running the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release &&

ninja

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: ninja test. Now, as the root user:
ninja install

