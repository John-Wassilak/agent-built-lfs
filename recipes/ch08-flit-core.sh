#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/flit-core.html
# title  : 8.54. Flit-Core-3.12.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: Flit-core is the distribution-building parts of Flit (a packaging tool for simple Python
#   ctx: modules). Approximate build time: less than 0.1 SBU Required disk space: 1.3 MB 8.54.1.
#   ctx: Installation of Flit-Core Build the package:
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD

# --- block 1 --------------------------------------------------
#   ctx: Install the package:
pip3 install --no-index --find-links dist flit_core

