#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/multimedia/alsa-lib.html
# title  : alsa-lib-1.2.15.3
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: In the Device Drivers ⇒ Sound card support ⇒ Advanced Linux Sound Architecture section
#   ctx: of the kernel configuration, select the settings and drivers appropriate for your
#   ctx: hardware. If necessary, recompile and install your new kernel. Installation of ALSA
#   ctx: Library Install ALSA Library by running the following commands:
./configure &&
make

# --- block 1 --------------------------------------------------
#   ctx: If you have Doxygen installed and you wish to build the library API documentation, run
#   ctx: the following commands from the top-level directory of the source tree:
#   REVIEWED [drop]: Optional API doc build needs Doxygen, not installed.
# make doc

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user, install the package and
#   ctx: recommended configuration files:
make install &&
tar -C /usr/share/alsa --strip-components=1 -xf ../alsa-ucm-conf-1.2.15.3.tar.bz2

# --- block 3 --------------------------------------------------
#   ctx: To install the API documentation, run the following command as the root user:
#   REVIEWED [drop]: Installs the doxygen docs from block 1, which was dropped.
# install -v -d -m755 /usr/share/doc/alsa-lib-1.2.15.3/html/search &&
# install -v -m644 doc/doxygen/html/*.* \
#                 /usr/share/doc/alsa-lib-1.2.15.3/html &&
# install -v -m644 doc/doxygen/html/search/* \
#                 /usr/share/doc/alsa-lib-1.2.15.3/html/search

