#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter07/gettext.html
# title  : 7.7. Gettext-1.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ns utilities for internationalization and localization. These allow programs to be
#   ctx: compiled with NLS (Native Language Support), enabling them to output messages in the
#   ctx: user's native language. Approximate build time: 1.5 SBU Required disk space: 526 MB
#   ctx: 7.7.1. Installation of Gettext For our temporary set of tools, we only need to install
#   ctx: three programs from Gettext. Prepare Gettext for compilation:
./configure --disable-shared

# --- block 1 --------------------------------------------------
#   ctx: The meaning of the configure option: --disable-shared We do not need to install any of
#   ctx: the shared Gettext libraries at this time, therefore there is no need to build them.
#   ctx: Compile the package:
make

# --- block 2 --------------------------------------------------
#   ctx: Install the msgfmt, msgmerge, and xgettext programs:
cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin

