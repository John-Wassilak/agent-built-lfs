#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.1-systemd book.
# source : book/13.1/chapter06/m4.html
# title  : 6.2 M4-1.4.21
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The M4 package contains a macro processor. Approximate build time: 0.1 SBU Required disk
#   ctx: space: 39 MB 6.2.1 Installation of M4 Ensure packages that use gnulib detect some newer
#   ctx: functions found in glibc-2.44.
cat > $LFS/usr/share/config.site << EOF
ac_cv_func_posix_spawn_file_actions_addchdir=yes
ac_cv_func_posix_spawn_file_actions_addfchdir=yes
EOF

# --- block 1 --------------------------------------------------
#   ctx: Prepare M4 for compilation:
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)

# --- block 2 --------------------------------------------------
#   ctx: Compile the package:
make

# --- block 3 --------------------------------------------------
#   ctx: Install the package:
make DESTDIR=$LFS install

