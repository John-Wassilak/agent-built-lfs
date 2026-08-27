#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS. Required by picom (>=1.7) for its config file
# parsing (picom.conf uses libconfig's syntax).
#
# Real bug found: the official 1.7.3 release tarball's generated
# grammar.c (bison output) has old K&R-style empty-parameter extern
# declarations (`extern int libconfig_yylex();`) that this system's GCC
# treats strictly as zero-argument prototypes under its default C
# standard, rather than the old "unspecified arguments" K&R meaning --
# a real, confirmed toolchain incompatibility, not a guess (build
# failed with "too many arguments to function 'libconfig_yylex'").
# Used 1.8.2 instead (no such issue), built via CMake since GitHub's
# tag tarball has no pre-generated ./configure and bootstrapping
# autotools would be more work than just using the CMakeLists.txt
# upstream already ships.
set -e

cmake -B build -S . -D CMAKE_BUILD_TYPE=None -D CMAKE_INSTALL_PREFIX=/usr -D BUILD_EXAMPLES=OFF -Wno-dev
cmake --build build
cmake --install build
