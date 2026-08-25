#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter05/linux-headers.html
# title  : 5.4. Linux-6.18.10 API Headers
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: imate build time: less than 0.1 SBU Required disk space: 1.7 GB 5.4.1. Installation of
#   ctx: Linux API Headers The Linux kernel needs to expose an Application Programming Interface
#   ctx: (API) for the system's C library (Glibc in LFS) to use. This is done by way of
#   ctx: sanitizing various C header files that are shipped in the Linux kernel source tarball.
#   ctx: Make sure there are no stale files embedded in the package:
make mrproper

# --- block 1 --------------------------------------------------
#   ctx: Now extract the user-visible kernel headers from the source. The recommended make target
#   ctx: “headers_install” cannot be used, because it requires rsync, which may not be available.
#   ctx: The headers are first placed in ./usr, then copied to the needed location.
make headers
find usr/include -type f ! -name '*.h' -delete
cp -rv usr/include $LFS/usr

