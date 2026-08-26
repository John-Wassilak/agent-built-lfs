#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/harfbuzz.html
# title  : harfBuzz-12.3.2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: 3 module, for the test suite), ragel, and wasm-micro-runtime Warning Recommended
#   ctx: dependencies are not strictly required to build the package. However, you might not get
#   ctx: expected results at runtime if you don't install them. Please do not report bugs with
#   ctx: this package if you have not installed the recommended dependencies. Installation of
#   ctx: HarfBuzz Install HarfBuzz by running the following commands:
mkdir build &&
cd    build &&

meson setup ..             \
      --prefix=/usr        \
      --buildtype=release  \
      -D graphite2=enabled &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: ninja test. Now, as the root user:
ninja install

