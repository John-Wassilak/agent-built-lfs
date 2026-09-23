#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/pst/itstool.html
# title  : itstool-2.0.7
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: red: 688 KB Estimated build time: less than 0.1 SBU Additional Downloads Required patch:
#   ctx: https://www.linuxfromscratch.org/patches/blfs/13.0/itstool-2.0.7-lxml-1.patch Itstool
#   ctx: Dependencies Required docbook-xml-4.5 and lxml-6.0.2 Installation of itstool First,
#   ctx: apply a patch to use lxml-6.0.2 for handling the XML files instead of the deprecated
#   ctx: (disabled by default) Python module from libxml2-2.15.1:
patch -Np1 -i ../itstool-2.0.7-lxml-1.patch

# --- block 1 --------------------------------------------------
#   ctx: Install itstool by running the following commands:
PYTHON=/usr/bin/python3 ./autogen.sh --prefix=/usr &&
make

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue: python3 tests/run_tests.py. Now, as the root user:
make install

