#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page for CLI11.
# rationale: Not in the BLFS 13.0 book. Real upstream release tarball
# (CLI11-2.7.2-Source.tar.gz, github.com/CLIUtils/CLI11), not an AUR/PKGBUILD
# reference -- header-only C++ library, upstream's own CMake install produces the
# CLI11Config.cmake find_package() needs, which is what quickshell's CMakeLists
# actually looks for ("Required Base Dependencies... cli11"). Tests/examples
# disabled -- library-only, nothing here runs its test suite.
set -e

mkdir build
cd build
cmake -D CMAKE_INSTALL_PREFIX=/usr \
      -D CMAKE_BUILD_TYPE=Release  \
      -D CLI11_BUILD_TESTS=OFF     \
      -D CLI11_BUILD_EXAMPLES=OFF  \
      -D CLI11_BUILD_DOCS=OFF      \
      ..
cmake --build .
cmake --install .
