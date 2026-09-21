#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter07/perl.html
# title  : 7.9. Perl-5.42.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Perl package contains the Practical Extraction and Report Language. Approximate
#   ctx: build time: 0.6 SBU Required disk space: 295 MB 7.9.1. Installation of Perl Prepare Perl
#   ctx: for compilation:
sh Configure -des                                         \
             -D prefix=/usr                               \
             -D vendorprefix=/usr                         \
             -D useshrplib                                \
             -D privlib=/usr/lib/perl5/5.42/core_perl     \
             -D archlib=/usr/lib/perl5/5.42/core_perl     \
             -D sitelib=/usr/lib/perl5/5.42/site_perl     \
             -D sitearch=/usr/lib/perl5/5.42/site_perl    \
             -D vendorlib=/usr/lib/perl5/5.42/vendor_perl \
             -D vendorarch=/usr/lib/perl5/5.42/vendor_perl

# --- block 1 --------------------------------------------------
#   ctx: ivlib,-D archlib,-D sitelib,... These settings define where Perl looks for installed
#   ctx: modules. The LFS editors chose to put them in a directory structure based on the
#   ctx: MAJOR.MINOR version of Perl (5.42) which allows upgrading Perl to newer patch levels
#   ctx: (the patch level is the last dot separated part in the full version string like 5.42.0)
#   ctx: without reinstalling all of the modules. Compile the package:
make

# --- block 2 --------------------------------------------------
#   ctx: Install the package:
make install

