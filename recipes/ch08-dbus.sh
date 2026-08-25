#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/dbus.html
# title  : 8.79. D-Bus-1.16.2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: er-user-login-session daemon (for general IPC needs among user applications). Also, the
#   ctx: message bus is built on top of a general one-to-one message passing framework, which can
#   ctx: be used by any two applications to communicate directly (without going through the
#   ctx: message bus daemon). Approximate build time: 0.1 SBU Required disk space: 17 MB 8.79.1.
#   ctx: Installation of D-Bus Prepare D-Bus for compilation:
mkdir build
cd    build

meson setup --prefix=/usr --buildtype=release --wrap-mode=nofallback ..

# --- block 1 --------------------------------------------------
#   ctx: The meaning of the meson options: --wrap-mode=nofallback This switch prevents meson from
#   ctx: attempting to download a copy of the Glib package for the tests. Compile the package:
ninja

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue:
#   TAGS: testsuite   [DISABLED - review]
# ninja test

# --- block 3 --------------------------------------------------
#   ctx: Many tests are disabled because they require additional packages that are not included
#   ctx: in LFS. Instructions for running the comprehensive test suite can be found in the BLFS
#   ctx: book. Install the package:
ninja install

# --- block 4 --------------------------------------------------
#   ctx: Create a symlink so that D-Bus and systemd can use the same machine-id file:
ln -sfv /etc/machine-id /var/lib/dbus

