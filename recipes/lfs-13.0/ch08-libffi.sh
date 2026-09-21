#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/libffi.html
# title  : 8.51. Libffi-3.5.2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: th-gcc-arch= parameter in the following command to an architecture name fully
#   ctx: implemented by both the host CPU and the CPU on that system. If this is not done, all
#   ctx: applications that link to libffi will trigger Illegal Operation Errors. If you cannot
#   ctx: figure out a value safe for both the CPUs, replace the parameter with --without-gcc-arch
#   ctx: to produce a generic library. Prepare Libffi for compilation:
./configure --prefix=/usr    \
            --disable-static \
            --with-gcc-arch=native

# --- block 1 --------------------------------------------------
#   ctx: option: --with-gcc-arch=native Ensure GCC optimizes for the current system. If this is
#   ctx: not specified, the system is guessed and the code generated may not be correct. If the
#   ctx: generated code will be copied from the native system to a less capable system, use the
#   ctx: less capable system as a parameter. For details about alternative system types, see the
#   ctx: x86 options in the GCC manual. Compile the package:
make

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue:
#   TAGS: testsuite   [DISABLED - review]
# make check

# --- block 3 --------------------------------------------------
#   ctx: Install the package:
make install

