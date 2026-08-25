#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter06/diffutils.html
# title  : 6.6. Diffutils-3.12
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Diffutils package contains programs that show the differences between files or
#   ctx: directories. Approximate build time: 0.1 SBU Required disk space: 35 MB 6.6.1.
#   ctx: Installation of Diffutils Prepare Diffutils for compilation:
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            gl_cv_func_strcasecmp_works=y \
            --build=$(./build-aux/config.guess)

# --- block 1 --------------------------------------------------
#   ctx: heck is absent and the configure script would have no value to use and error out. The
#   ctx: upstream has already fixed the issue, but to apply the fix we'd need to run autoconf
#   ctx: that the host distro may lack. So we just specify the check result (y as we know the
#   ctx: strcasecmp function in Glibc-2.43 works fine) instead, then configure will just use the
#   ctx: specified value and skip the check. Compile the package:
make

# --- block 2 --------------------------------------------------
#   ctx: Install the package:
make DESTDIR=$LFS install

