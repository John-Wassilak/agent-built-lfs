#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/Python.html
# title  : 8.53. Python-3.14.3
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Python 3 package contains the Python development environment. It is useful for
#   ctx: object-oriented programming, writing scripts, prototyping large programs, and developing
#   ctx: entire applications. Python is an interpreted computer language. Approximate build time:
#   ctx: 2.6 SBU Required disk space: 494 MB 8.53.1. Installation of Python 3 Prepare Python for
#   ctx: compilation:
./configure --prefix=/usr          \
            --enable-shared        \
            --with-system-expat    \
            --enable-optimizations \
            --without-static-libpython

# --- block 1 --------------------------------------------------
#   ctx: The meaning of the configure options: --with-system-expat This switch enables linking
#   ctx: against the system version of Expat. --enable-optimizations This switch enables
#   ctx: extensive, but time-consuming, optimization steps. The interpreter is built twice; tests
#   ctx: performed on the first build are used to improve the optimized final version. Compile
#   ctx: the package:
make

# --- block 2 --------------------------------------------------
#   ctx: Some tests are known to occasionally hang indefinitely. So to test the results, run the
#   ctx: test suite but set a 2-minute time limit for each test case:
#   TAGS: testsuite   [DISABLED - review]
# make test TESTOPTS="--timeout 120"

# --- block 3 --------------------------------------------------
#   ctx: For a relatively slow system you may need to increase the time limit and 1 SBU (measured
#   ctx: when building Binutils pass 1 with one CPU core) should be enough. Some tests are flaky,
#   ctx: so the test suite will automatically re-run failed tests. If a test failed but then
#   ctx: passed when re-run, it should be considered as passed. Install the package:
make install

# --- block 4 --------------------------------------------------
#   ctx: lable). But LFS considers pip3 to be a part of Python 3, so it should not be updated
#   ctx: separately. Also, an update from a pre-built wheel would deviate from our objective: to
#   ctx: build a Linux system from source code. So the warning about a new version of pip3 should
#   ctx: be ignored as well. If you wish, you can suppress all these warnings by running the
#   ctx: following command, which creates a configuration file:
cat > /etc/pip.conf << EOF
[global]
root-user-action = ignore
disable-pip-version-check = true
EOF

# --- block 5 --------------------------------------------------
#   ctx: lready installed module automatically. When using the pip3 install command to upgrade a
#   ctx: module (for example, from meson-0.61.3 to meson-0.62.0), insert the option --upgrade
#   ctx: into the command line. If it's really necessary to downgrade a module, or reinstall the
#   ctx: same version for some reason, insert --force-reinstall --no-deps into the command line.
#   ctx: If desired, install the preformatted documentation:
install -v -dm755 /usr/share/doc/python-3.14.3/html

tar --strip-components=1  \
    --no-same-owner       \
    --no-same-permissions \
    -C /usr/share/doc/python-3.14.3/html \
    -xvf ../python-3.14.3-docs-html.tar.bz2

