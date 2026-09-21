#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/pcre2.html
# title  : 8.13. Pcre2-10.47
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The pcre2 package contains a new generation of the Perl Compatible Regular Expression
#   ctx: libraries. Approximate build time: 0.2 SBU Required disk space: 28 MB 8.13.1.
#   ctx: Installation of Pcre2 Prepare pcre2 for compilation:
./configure --prefix=/usr                       \
            --docdir=/usr/share/doc/pcre2-10.47 \
            --enable-unicode                    \
            --enable-jit                        \
            --enable-pcre2-16                   \
            --enable-pcre2-32                   \
            --enable-pcre2grep-libz             \
            --enable-pcre2grep-libbz2           \
            --enable-pcre2test-libreadline      \
            --disable-static

# --- block 1 --------------------------------------------------
#   ctx: ter support. --enable-pcre2-32 This option enables 32 bit character support.
#   ctx: --enable-pcre2grep-libz This option adds support for reading .gz compressed files to
#   ctx: pcre2grep. --enable-pcre2grep-libbz2 This option adds support for reading .bz2
#   ctx: compressed files to pcre2grep. --enable-pcre2test-libreadline This option adds line
#   ctx: editing and history features to the pcre2test program. Compile the package:
make

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue:
#   TAGS: testsuite   [DISABLED - review]
# make check

# --- block 3 --------------------------------------------------
#   ctx: Install the package:
make install

