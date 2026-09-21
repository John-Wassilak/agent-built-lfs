#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/packaging.html
# title  : 8.55. Packaging-26.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: t the interoperability specifications which have clearly one correct behaviour (PEP440)
#   ctx: or benefit greatly from having a single shared implementation (PEP425). This includes
#   ctx: utilities for version handling, specifiers, markers, tags, and requirements. Approximate
#   ctx: build time: less than 0.1 SBU Required disk space: 1.6 MB 8.55.1. Installation of
#   ctx: Packaging Compile packaging with the following command:
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD

# --- block 1 --------------------------------------------------
#   ctx: Install packaging with the following command:
pip3 install --no-index --find-links dist packaging

