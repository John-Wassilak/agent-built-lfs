#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/libusb.html
# title  : libusb-1.0.29
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: For more details on setting up USB devices, see the section called “USB Device Issues”.
#   ctx: Installation of libusb Install libusb by running the following commands:
./configure --prefix=/usr --disable-static &&
make

# --- block 1 --------------------------------------------------
#   ctx: If Doxygen is installed and you wish to build the API documentation, issue the following
#   ctx: commands:
#   REVIEWED [drop]: Optional doxygen API docs, not installed.
# pushd doc                &&
#   doxygen -u doxygen.cfg &&
#   make docs              &&
# popd

# --- block 2 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
make install

# --- block 3 --------------------------------------------------
#   ctx: If you built the API documentation, install it using the following commands as the root
#   ctx: user:
#   REVIEWED [drop]: Installs the doxygen docs from block 1, which was dropped.
# install -v -d -m755 /usr/share/doc/libusb-1.0.29/apidocs &&
# install -v -m644    doc/api-1.0/* \
#                     /usr/share/doc/libusb-1.0.29/apidocs

