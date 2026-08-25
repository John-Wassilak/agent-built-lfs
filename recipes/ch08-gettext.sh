#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/gettext.html
# title  : 8.34. Gettext-1.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Gettext package contains utilities for internationalization and localization. These
#   ctx: allow programs to be compiled with NLS (Native Language Support), enabling them to
#   ctx: output messages in the user's native language. Approximate build time: 2.1 SBU Required
#   ctx: disk space: 447 MB 8.34.1. Installation of Gettext Prepare Gettext for compilation:
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/gettext-1.0

# --- block 1 --------------------------------------------------
#   ctx: Compile the package:
make

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue:
#   TAGS: testsuite   [DISABLED - review]
# make check

# --- block 3 --------------------------------------------------
#   ctx: Install the package:
make install
chmod -v 0755 /usr/lib/preloadable_libintl.so

