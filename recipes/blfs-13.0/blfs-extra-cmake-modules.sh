#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/kde/extra-cmake-modules.html
# title  : Extra-CMake-Modules-6.23.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: b9c562bac371dcf693ceccb431cad782 Download size: 332 KB Estimated disk space required: 11
#   ctx: MB Estimated build time: less than 0.1 SBU Extra CMake Modules Dependencies Required
#   ctx: CMake-4.2.3 Recommended Qt-6.10.2 Optional sphinx-9.1.0 (for building documentation) and
#   ctx: ReuseTool (for running internal tests) Installation of Extra CMake Modules Install Extra
#   ctx: CMake Modules by running the following commands:
sed -i '/"lib64"/s/64//' kde-modules/KDEInstallDirsCommon.cmake &&

sed -e '/PACKAGE_INIT/i set(SAVE_PACKAGE_PREFIX_DIR "${PACKAGE_PREFIX_DIR}")' \
    -e '/^include/a set(PACKAGE_PREFIX_DIR "${SAVE_PACKAGE_PREFIX_DIR}")' \
    -i ECMConfig.cmake.in &&

mkdir build &&
cd    build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr \
      -D BUILD_WITH_QT6=ON         \
      -D DOC_INSTALL_DIR=/usr/share/doc/extra-cmake-modules-6.23.0 \
      .. &&
make

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. Note Unlike other KF6 packages, this
#   ctx: module is installed in /usr because it can be used by some non-KF6 packages. Now, as the
#   ctx: root user:
make install

