#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/findutils.html
# title  : 8.64. Findutils-4.10.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: and to create, maintain, and search a database (often faster than the recursive find,
#   ctx: but unreliable unless the database has been updated recently). Findutils also supplies
#   ctx: the xargs program, which can be used to run a specified command on each file selected by
#   ctx: a search. Approximate build time: 0.7 SBU Required disk space: 62 MB 8.64.1.
#   ctx: Installation of Findutils Prepare Findutils for compilation:
./configure --prefix=/usr --localstatedir=/var/lib/locate

# --- block 1 --------------------------------------------------
#   ctx: The meaning of the configure options: --localstatedir This option moves the locate
#   ctx: database to /var/lib/locate, which is the FHS-compliant location. Compile the package:
make

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue:
chown -R tester .
su tester -c "PATH=$PATH make check"

# --- block 3 --------------------------------------------------
#   ctx: Install the package:
make install

