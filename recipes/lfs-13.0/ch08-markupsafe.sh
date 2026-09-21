#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/markupsafe.html
# title  : 8.76. MarkupSafe-3.0.3
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: MarkupSafe is a Python module that implements an XML/HTML/XHTML Markup safe string.
#   ctx: Approximate build time: less than 0.1 SBU Required disk space: 692 KB 8.76.1.
#   ctx: Installation of MarkupSafe Compile MarkupSafe with the following command:
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. Install the package:
pip3 install --no-index --find-links dist Markupsafe

