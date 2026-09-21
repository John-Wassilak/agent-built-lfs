#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/pkgmgt.html
# title  : 8.2. Package Management
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ning a shared library is updated, and the name of the library doesn't change, but a
#   ctx: severe issue (especially, a security vulnerability) is fixed, all running programs
#   ctx: linked to the shared library should be restarted. The following command, run as root
#   ctx: after the update is complete, will list which processes are using the old versions of
#   ctx: those libraries (replace libfoo with the name of the library):
grep -l 'libfoo.*deleted' /proc/*/maps | tr -cd 0-9\\n | xargs -r ps u

# --- block 1 --------------------------------------------------
#   ctx: . A few of the popular ones include Stow, Epkg, Graft, and Depot. The installation
#   ctx: script needs to be fooled, so the package thinks it is installed in /usr though in
#   ctx: reality it is installed in the /usr/pkg hierarchy. Installing in this manner is not
#   ctx: usually a trivial task. For example, suppose you are installing a package libfoo-1.1.
#   ctx: The following instructions may not install the package properly:
./configure --prefix=/usr/pkg/libfoo/1.1
make
make install

# --- block 2 --------------------------------------------------
#   ctx: The installation will work, but the dependent packages may not link to libfoo as you
#   ctx: would expect. If you compile a package that links against libfoo, you may notice that it
#   ctx: is linked to /usr/pkg/libfoo/1.1/lib/libfoo.so.1 instead of /usr/lib/libfoo.so.1 as you
#   ctx: would expect. The correct approach is to use the DESTDIR variable to direct the
#   ctx: installation. This approach works as follows:
./configure --prefix=/usr
make
make DESTDIR=/usr/pkg/libfoo/1.1 install

