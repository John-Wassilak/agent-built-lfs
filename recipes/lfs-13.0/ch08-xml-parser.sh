#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/xml-parser.html
# title  : 8.45. XML::Parser-2.47
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The XML::Parser module is a Perl interface to James Clark's XML parser, Expat.
#   ctx: Approximate build time: less than 0.1 SBU Required disk space: 2.3 MB 8.45.1.
#   ctx: Installation of XML::Parser Prepare XML::Parser for compilation:
perl Makefile.PL

# --- block 1 --------------------------------------------------
#   ctx: Compile the package:
make

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue:
#   TAGS: testsuite   [DISABLED - review]
# make test

# --- block 3 --------------------------------------------------
#   ctx: Install the package:
make install

