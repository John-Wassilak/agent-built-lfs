#!/bin/bash
# HAND-AUTHORED recipe from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/basicnet/libevent.html
# title  : libevent-2.1.12
# rationale: Firefox Recommended dependency (--with-system-libevent in the
# book's mozconfig). No dependencies of its own beyond what's already
# present. Tests/API docs skipped (Doxygen not installed, no verification
# value here -- same policy as every other test suite in this project).
set -e

sed -i 's/python/&3/' event_rpcgen.py

./configure --prefix=/usr --disable-static
make

make install

echo "### pkg-config"
pkg-config --modversion libevent 2>&1 || true
