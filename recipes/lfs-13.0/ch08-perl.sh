#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/perl.html
# title  : 8.44. Perl-5.42.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: l package contains the Practical Extraction and Report Language. Approximate build time:
#   ctx: 1.3 SBU Required disk space: 257 MB 8.44.1. Installation of Perl This version of Perl
#   ctx: builds the Compress::Raw::Zlib and Compress::Raw::BZip2 modules. By default Perl will
#   ctx: use an internal copy of the sources for the build. Issue the following command so that
#   ctx: Perl will use the libraries installed on the system:
export BUILD_ZLIB=False
export BUILD_BZIP2=0

# --- block 1 --------------------------------------------------
#   ctx: To have full control over the way Perl is set up, you can remove the “-des” options from
#   ctx: the following command and hand-pick the way this package is built. Alternatively, use
#   ctx: the command exactly as shown below to use the defaults that Perl auto-detects:
sh Configure -des                                          \
             -D prefix=/usr                                \
             -D vendorprefix=/usr                          \
             -D privlib=/usr/lib/perl5/5.42/core_perl      \
             -D archlib=/usr/lib/perl5/5.42/core_perl      \
             -D sitelib=/usr/lib/perl5/5.42/site_perl      \
             -D sitearch=/usr/lib/perl5/5.42/site_perl     \
             -D vendorlib=/usr/lib/perl5/5.42/vendor_perl  \
             -D vendorarch=/usr/lib/perl5/5.42/vendor_perl \
             -D man1dir=/usr/share/man/man1                \
             -D man3dir=/usr/share/man/man3                \
             -D pager="/usr/bin/less -isR"                 \
             -D useshrplib                                 \
             -D usethreads

# --- block 2 --------------------------------------------------
#   ctx: The meaning of the new Configure options: -D pager="/usr/bin/less -isR" This ensures
#   ctx: that less is used instead of more. -D man1dir=/usr/share/man/man1 -D
#   ctx: man3dir=/usr/share/man/man3 Since Groff is not installed yet, Configure will not create
#   ctx: man pages for Perl. These parameters override this behavior. -D usethreads Build Perl
#   ctx: with support for threads. Compile the package:
make

# --- block 3 --------------------------------------------------
#   ctx: To test the results, issue:
TEST_JOBS=$(nproc) make test_harness

# --- block 4 --------------------------------------------------
#   ctx: Install the package and clean up:
make install
unset BUILD_ZLIB BUILD_BZIP2

