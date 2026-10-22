#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS/SLFS/GLFS 13.1 page for libcap-ng. BLFS names it only
# as an optional dependency (qemu, cifs-utils).
# source: github.com/stevegrubb/libcap-ng, tag v0.9.6 (released 2026-09-09), GitHub
# archive tarball. Arch carries it in [core].
#
# rationale: virtiofsd (next step) links it through the capng crate to drop the
# capabilities it does not need. Added 2026-10-22 for the file share between server
# and its Windows guest (packages.py seq 274).
#
# A GitHub archive has no generated configure, so autogen.sh (autoreconf only) runs
# first; autoconf, automake, libtool and pkg-config are all LFS chapter 8.
#
# --without-python / --without-python3: the bindings need SWIG, which is not built
# here, and nothing uses them. --disable-static: nothing links it statically.
# cap-audit and the deprecated utilities stay at their default, off.
set -e

./autogen.sh
./configure --prefix=/usr       \
            --without-python    \
            --without-python3   \
            --disable-static
make

make install
