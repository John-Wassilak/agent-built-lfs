#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/graphite2.html
# title  : Graphite2-1.3.14
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: 1.16.1, texlive-20250308 (or install-tl-unx), and dblatex (for PDF docs) To execute the
#   ctx: test suite you will need FontTools (Python 3 module), otherwise, the "cmp" tests fail.
#   ctx: Optional (at runtime) You will need at least one suitable graphite font for the package
#   ctx: to be useful. Installation of Graphite2 Some tests fail if FontTools (Python 3 module)
#   ctx: is not installed. These tests can be removed with:
sed -i '/cmptest/d' tests/CMakeLists.txt

# --- block 1 --------------------------------------------------
#   ctx: Fix building this package with CMake 4.0 by updating its syntax to conform to newer
#   ctx: versions of CMake:
sed -i '/cmake_policy(SET CMP0012 NEW)/d' CMakeLists.txt &&
sed -i 's/PythonInterp/Python3/' CMakeLists.txt          &&
find . -name CMakeLists.txt | xargs sed -i 's/VERSION 2.8.0 FATAL_ERROR/VERSION 4.0.0/'

# --- block 2 --------------------------------------------------
#   ctx: Now fix a problem when building with gcc-15:
sed -i '/Font.h/i #include <cstdint>' tests/featuremap/featuremaptest.cpp

# --- block 3 --------------------------------------------------
#   ctx: Install Graphite2 by running the following commands:
mkdir build &&
cd    build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr .. &&
make

# --- block 4 --------------------------------------------------
#   ctx: If you wish to build the documentation, issue:
#   REVIEWED [drop]: 'If you wish to build the documentation, issue: make docs' -- explicitly optional, not needed.
# make docs

# --- block 5 --------------------------------------------------
#   ctx: To test the results, issue: make test. One test named nametabletest is known to fail.
#   ctx: Now, as the root user:
make install

# --- block 6 --------------------------------------------------
#   ctx: If you built the documentation, install, as the root user:
#   REVIEWED [drop]: Installs the documentation built by block 4. Not built, so nothing to install.
# install -v -d -m755 /usr/share/doc/graphite2-1.3.14 &&
# 
# cp      -v -f    doc/{GTF,manual}.html \
#                     /usr/share/doc/graphite2-1.3.14 &&
# cp      -v -f    doc/{GTF,manual}.pdf \
#                     /usr/share/doc/graphite2-1.3.14

