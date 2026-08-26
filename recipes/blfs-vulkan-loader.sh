#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/x/vulkan-loader.html
# title  : Vulkan-Loader-1.4.341.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: r some tests of this package. The system certificate store may need to be set up with
#   ctx: make-ca-1.16.1 before testing this package. Installation of Vulkan-Loader Note If this
#   ctx: package is being installed on a system where Mesa has already been installed previously,
#   ctx: please rebuild Mesa-25.3.5 after this package to install Vulkan graphics drivers.
#   ctx: Install Vulkan-Loader by running the following commands:
mkdir build &&
cd    build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr   \
      -D CMAKE_BUILD_TYPE=Release    \
      -D CMAKE_SKIP_INSTALL_RPATH=ON \
      -G Ninja .. &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: To run the test suite, issue (note that the command will use git-2.53.0 to download a
#   ctx: copy of GoogleTest for building the test suite):
sed "s/'git', 'clone'/&, '--depth=1', '-b', self.commit/" \
    -i ../scripts/update_deps.py &&
cmake -D BUILD_TESTS=ON -D UPDATE_DEPS=ON .. &&
ninja &&
ninja test

# --- block 2 --------------------------------------------------
#   ctx: Now, as the root user:
ninja install

