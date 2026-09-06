#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/boost.html
# title  : boost-1.90.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: disk space required: 861 MB (201 MB installed) Estimated build time: 1.8 SBU (Using
#   ctx: parallelism=4; add 0.2 SBU for tests) Boost Dependencies Recommended Which-2.23 Optional
#   ctx: ICU-78.2, NumPy-2.4.2, and Open MPI Editor Notes:
#   ctx: https://wiki.linuxfromscratch.org/blfs/wiki/boost Installation of Boost First, fix a
#   ctx: build issue which occurs in the stacktrace library. This issue is specific to i686
#   ctx: systems.
case $(uname -m) in
   i?86)
      sed -e "s/defined(__MINGW32__)/& || defined(__i386__)/" \
          -i ./libs/stacktrace/src/exception_headers.h ;;
esac

# --- block 1 --------------------------------------------------
#   ctx: This package can be built with several jobs running in parallel. In the instructions
#   ctx: below, all available logical cores are used. Replace $(nproc) with the number of logical
#   ctx: cores you want to use if you don't want to use all. Install Boost by running the
#   ctx: following commands:
./bootstrap.sh --prefix=/usr --with-python=python3 &&
./b2 stage -j$(nproc) threading=multi link=shared

# --- block 2 --------------------------------------------------
#   ctx: To run Boost.Build's regression tests, issue pushd tools/build/test; python3
#   ctx: test_all.py; popd. Note Boost installs many versioned directories in /usr/lib/cmake. If
#   ctx: a new version of Boost is installed over a previous version, the older cmake directories
#   ctx: need to be explicitly removed. To do this, run as the root user:
#   REVIEWED [drop]: Book's own text is explicitly conditional on an upgrade: 'Boost installs many versioned directories in /usr/lib/cmake. If a new version of Boost is installed over a previous version, the older cmake directories need to be explicitly removed.' A fresh install has no previous Boost version's cmake directories to remove -- the glob would just match nothing (harmless) but there's nothing to clean up, so it's dropped as inapplicable rather than kept as a no-op.
# rm -rf /usr/lib/cmake/[Bb]oost*

# --- block 3 --------------------------------------------------
#   ctx: before installing the new version. Now, as the root user:
./b2 install threading=multi link=shared

