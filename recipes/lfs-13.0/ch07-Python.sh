#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter07/Python.html
# title  : 7.10. Python-3.14.3
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: cripts, prototyping large programs, and developing entire applications. Python is an
#   ctx: interpreted computer language. Approximate build time: 0.5 SBU Required disk space: 592
#   ctx: MB 7.10.1. Installation of Python Note There are two package files whose name starts
#   ctx: with the “python” prefix. The one to extract from is Python-3.14.3.tar.xz (notice the
#   ctx: uppercase first letter). Prepare Python for compilation:
./configure --prefix=/usr       \
            --enable-shared     \
            --without-ensurepip \
            --without-static-libpython

# --- block 1 --------------------------------------------------
#   ctx: The meaning of the configure option: --enable-shared This switch prevents installation
#   ctx: of static libraries. --without-ensurepip This switch disables the Python package
#   ctx: installer, which is not needed at this stage. --without-static-libpython This switch
#   ctx: prevents building a large, but unneeded, static library. Compile the package:
make

# --- block 2 --------------------------------------------------
#   ctx: Note Some Python 3 modules can't be built now because the dependencies are not installed
#   ctx: yet. For the ssl module, a message Python requires a OpenSSL 1.1.1 or newer is
#   ctx: outputted. The message should be ignored. Just make sure the toplevel make command has
#   ctx: not failed. The optional modules are not needed now and they will be built in Chapter 8.
#   ctx: Install the package:
make install

