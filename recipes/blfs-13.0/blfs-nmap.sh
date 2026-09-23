#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/basicnet/nmap.html
# title  : Nmap-7.98
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: version. liblinear-250, libpcap-1.10.6, libssh2-1.11.1, Lua-5.4.8, and PyGObject-3.54.5
#   ctx: Optional libdnet and setuptools-gettext (currently useless) Installation of Nmap Make
#   ctx: the build system use the Setuptools Python module from LFS instead of downloading a copy
#   ctx: from the Internet, and install the Python wheels already created when running the make
#   ctx: instead of rebuilding them again on make install:
sed -ri Makefile.in \
    -e 's#-m build#& --no-isolation#'  \
    -e '/pip install/s#(ZENMAP|NDIFF)DIR\)/#&dist/*.whl#'

# --- block 1 --------------------------------------------------
#   ctx: Remove a useless dependency on setuptools-gettext:
sed 's/, "setuptools-gettext"//' -i zenmap/pyproject.toml

# --- block 2 --------------------------------------------------
#   ctx: Install Nmap by running the following commands:
./configure --prefix=/usr &&
make

# --- block 3 --------------------------------------------------
#   ctx: If you wish to run the test suite, run the following command:
#   REVIEWED [drop]: Test-suite preparation only: the book introduces this sed with 'If you wish to run the test suite, run the following command', and it edits ndiff/ndifftest.py, which nothing but block 4 uses. Dropped with block 4.
# sed -e '/import imp/d'                \
#     -e 's/^ndiff = .*$/import ndiff/' \
#     -i ndiff/ndifftest.py

# --- block 4 --------------------------------------------------
#   ctx: Tests need a graphical session and to be run as the root user. To test the results,
#   ctx: issue:
#   REVIEWED [drop]: The book's own condition: 'Tests need a graphical session and to be run as the root user.' lfsbuild runs as root with no graphical session, so on any host this block either fails or needs a display handed to a root build. Optional; nmap's install does not depend on it.
# make check

# --- block 5 --------------------------------------------------
#   ctx: Now, as the root user:
make install

