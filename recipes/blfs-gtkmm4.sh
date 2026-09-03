#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/x/gtkmm4.html
# title  : Gtkmm-4.20.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: mm/4.20/gtkmm-4.20.0.tar.xz Download MD5 sum: ee06c6c7ef69845ca23087b5cc0d84ff Download
#   ctx: size: 17 MB Estimated disk space required: 214 MB (with tests) Estimated build time: 0.9
#   ctx: SBU (With tests; both using parallelism=4) Gtkmm Dependencies Required GTK-4.20.3 and
#   ctx: Pangomm-2.56.1 Optional Doxygen-1.16.1 and Vulkan-Loader-1.4.341.0 Installation of Gtkmm
#   ctx: Install Gtkmm by running the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release .. &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: ninja test. Note that you must be in a graphical
#   ctx: environment, as the tests try to open some windows. Now, as the root user:
ninja install

# --- block 2 --------------------------------------------------
#   ctx: If you have built the documentation (see Command Explanations below) it was installed to
#   ctx: /usr/share/doc/gtkmm-4.0. For consistency, move it to a versioned directory as the root
#   ctx: user:
mv -v /usr/share/doc/gtkmm-4.0 /usr/share/doc/gtkmm-4.20.0

