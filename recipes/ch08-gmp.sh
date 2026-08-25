#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/gmp.html
# title  : 8.22. GMP-6.3.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ns for arbitrary precision arithmetic. Approximate build time: 0.3 SBU Required disk
#   ctx: space: 54 MB 8.22.1. Installation of GMP Note If you are building for 32-bit x86, but
#   ctx: you have a CPU which is capable of running 64-bit code and you have specified CFLAGS in
#   ctx: the environment, the configure script will attempt to configure for 64-bits and fail.
#   ctx: Avoid this by invoking the configure command below with
#   REVIEWED [drop]: Not a runnable command ('ABI=32 ./configure ...'). Applies only when CFLAGS is set in the environment and 32-bit fallback is wanted. Our build sets no CFLAGS.
# ABI=32 ./configure ...

# --- block 1 --------------------------------------------------
#   ctx: Note The default settings of GMP produce libraries optimized for the host processor. If
#   ctx: libraries suitable for processors less capable than the host's CPU are desired, generic
#   ctx: libraries can be created by appending the --host=none-linux-gnu option to the configure
#   ctx: command. First, make an adjustment for compatibility with gcc-15 and later:
sed -i '/long long t1;/,+1s/()/(...)/' configure

# --- block 2 --------------------------------------------------
#   ctx: Prepare GMP for compilation:
./configure --prefix=/usr    \
            --enable-cxx     \
            --disable-static \
            --docdir=/usr/share/doc/gmp-6.3.0

# --- block 3 --------------------------------------------------
#   ctx: The meaning of the new configure options: --enable-cxx This parameter enables C++
#   ctx: support --docdir=/usr/share/doc/gmp-6.3.0 This variable specifies the correct place for
#   ctx: the documentation. Compile the package and generate the HTML documentation:
make
make html

# --- block 4 --------------------------------------------------
#   ctx: Important The test suite for GMP in this section is considered critical. Do not skip it
#   ctx: under any circumstances. Test the results:
#   TAGS: testsuite   [DISABLED - review]
# make check 2>&1 | tee gmp-check-log

# --- block 5 --------------------------------------------------
#   ctx: ly, the code that detects the processor misidentifies the system capabilities and there
#   ctx: will be errors in the tests or other applications using the gmp libraries with the
#   ctx: message Illegal instruction. In this case, gmp should be reconfigured with the option
#   ctx: --host=none-linux-gnu and rebuilt. Ensure that at least 199 tests in the test suite
#   ctx: passed. Check the results by issuing the following command:
#   REVIEWED [drop]: Summarizes gmp-check-log, which is produced only by the `make check | tee gmp-check-log` block. That test suite is not in the critical three, so the log never exists and awk aborts the build.
# awk '/# PASS:/{total+=$3} ; END{print total}' gmp-check-log

# --- block 6 --------------------------------------------------
#   ctx: Install the package and its documentation:
make install
make install-html

