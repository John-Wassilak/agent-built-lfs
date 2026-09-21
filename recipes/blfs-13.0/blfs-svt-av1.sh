#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/multimedia/svt-av1.html
# title  : SVT-AV1-4.0.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ed build time: 0.7 SBU (using parallelism=4; add 31 SBU for tests) SVT-AV1 Dependencies
#   ctx: Required CMake-4.2.3 Recommended NASM-3.01 Optional Valgrind-3.26.0 Note An Internet
#   ctx: connection is needed for some tests of this package. The system certificate store may
#   ctx: need to be set up with make-ca-1.16.1 before testing this package. Installation of
#   ctx: SVT-AV1 Install SVT-AV1 by running the following commands:
mkdir build &&
cd    build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr   \
      -D CMAKE_BUILD_TYPE=Release    \
      -D CMAKE_SKIP_INSTALL_RPATH=ON \
      -D BUILD_SHARED_LIBS=ON        \
      -W no-dev -G Ninja .. &&

ninja

# --- block 1 --------------------------------------------------
#   ctx: The test suite is very long and doesn't provide meaningful results. If you want to test
#   ctx: the results anyway, issue:
#   REVIEWED [drop]: Optional test suite, explicitly called out by the book as very long (31 SBU) and not meaningful.
# cmake .. -D BUILD_TESTING=ON &&
# ninja                        &&
# ninja TestVectors            &&
# SVT_AV1_TEST_VECTOR_PATH=$PWD/../test/vectors \
# ctest -V -O testlog.txt --timeout 10800

# --- block 2 --------------------------------------------------
#   ctx: tem, you may need to increase the timeout for the tests (see the SBU value for the tests
#   ctx: on top of the page). In the SvtAv1ApiTests test, 12 run_paramter_check subtests are
#   ctx: known to fail. The test harness will download a copy of libaom (even if libaom-3.13.1 is
#   ctx: already installed, the test harness is still unable to use the system installation) and
#   ctx: some videos as test inputs. Now, as the root user:
ninja install

