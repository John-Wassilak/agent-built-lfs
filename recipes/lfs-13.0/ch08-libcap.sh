#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/libcap.html
# title  : 8.27. Libcap-2.77
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: set of distinct privileges. Approximate build time: less than 0.1 SBU Required disk
#   ctx: space: 3.1 MB 8.27.1. Installation of Libcap Note If updating this package on an
#   ctx: existing system and the go compiler is installed, prevent a build error by using export
#   ctx: GOLANG=no before running the commands below. Be sure to unset GOLANG after installation
#   ctx: is complete. Prevent static libraries from being installed:
sed -i '/install -m.*STA/d' libcap/Makefile

# --- block 1 --------------------------------------------------
#   ctx: Compile the package:
make prefix=/usr lib=lib

# --- block 2 --------------------------------------------------
#   ctx: The meaning of the make option: lib=lib This parameter sets the library directory to
#   ctx: /usr/lib rather than /usr/lib64 on x86_64. It has no effect on x86. To test the results,
#   ctx: issue:
#   TAGS: testsuite   [DISABLED - review]
# make test

# --- block 3 --------------------------------------------------
#   ctx: Install the package:
make prefix=/usr lib=lib install

