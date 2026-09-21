#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/cmake.html
# title  : CMake-4.2.3
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: 10 (for use during tests), Qt-6.10.2 (for the Qt-based GUI), sphinx-9.1.0 (for building
#   ctx: documents), Subversion-1.14.5 (for testing), cppdap, jsoncpp, and rhash Note An Internet
#   ctx: connection is needed for some tests of this package. The system certificate store may
#   ctx: need to be set up with make-ca-1.16.1 before testing this package. Installation of CMake
#   ctx: Install CMake by running the following commands:
sed -i '/"lib64"/s/64//' Modules/GNUInstallDirs.cmake &&

./configure --prefix=/usr        \
            --system-curl         \
            --system-zlib         \
            --system-expat        \
            --mandir=/share/man  \
            --docdir=/share/doc/cmake-4.2.3 &&
make

# --- block 1 --------------------------------------------------
#   ctx: use bin/ctest -R "problem1-test" and, to omit it, use bin/ctest -E "problem1-test".
#   ctx: These options can be used together: bin/ctest -R "problem1-test" -E "problem2-test".
#   ctx: Option -N can be used to display all available tests, and you can run bin/ctest for a
#   ctx: sub-set of tests by using separated by spaces names or numbers as options. Option --help
#   ctx: can be used to show all options. Now, as the root user:
make install

