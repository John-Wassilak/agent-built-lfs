#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/x/hicolor-icon-theme.html
# title  : hicolor-icon-theme-0.18
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: work properly using an LFS 13.0 platform. Package Information Download (HTTP):
#   ctx: https://icon-theme.freedesktop.org/releases/hicolor-icon-theme-0.18.tar.xz Download MD5
#   ctx: sum: ef14f3af03bcde9ed134aad626bdbaad Download size: 32 KB Estimated disk space
#   ctx: required: 644 KB Estimated build time: less than 0.1 SBU Installation of
#   ctx: hicolor-icon-theme Install hicolor-icon-theme by running the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release .. &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
ninja install

