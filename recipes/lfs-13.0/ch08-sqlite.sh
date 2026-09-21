#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/sqlite.html
# title  : 8.52. Sqlite-3510200
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Sqlite package is a software library that implements a self-contained, serverless,
#   ctx: zero-configuration, transactional SQL database engine. Approximate build time: 0.4 SBU
#   ctx: Required disk space: 124 MB 8.52.1. Installation of Sqlite Unpack the documentation:
tar -xf ../sqlite-doc-3510200.tar.xz

# --- block 1 --------------------------------------------------
#   ctx: Prepare Sqlite for compilation with:
./configure --prefix=/usr     \
            --disable-static  \
            --enable-fts{4,5} \
            CPPFLAGS="-D SQLITE_ENABLE_COLUMN_METADATA=1 \
                      -D SQLITE_ENABLE_UNLOCK_NOTIFY=1   \
                      -D SQLITE_ENABLE_DBSTAT_VTAB=1     \
                      -D SQLITE_SECURE_DELETE=1"

# --- block 2 --------------------------------------------------
#   ctx: TS) extension. CPPFLAGS="-D SQLITE_ENABLE_COLUMN_METADATA=1 ... Some applications
#   ctx: require these options to be turned on. The only way to do this is to include them in the
#   ctx: CFLAGS or CPPFLAGS. We use the latter so the default value (or any value set by the
#   ctx: user) of CFLAGS won't be affected. For further information on what can be specified see
#   ctx: https://www.sqlite.org/compile.html. Compile the package:
make LDFLAGS.rpath=""

# --- block 3 --------------------------------------------------
#   ctx: The LDFLAGS.rpath="" option prevents hard coding library search paths (rpath) into the
#   ctx: shared library. This package does not need rpath for an installation into the standard
#   ctx: location, and rpath may sometimes cause unwanted effects or even security issues. This
#   ctx: package does not come with a test suite. Install the package:
make install

# --- block 4 --------------------------------------------------
#   ctx: If desired, install the documentation:
install -v -m755 -d /usr/share/doc/sqlite-3.51.2
cp -v -R sqlite-doc-3510200/* /usr/share/doc/sqlite-3.51.2

