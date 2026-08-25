#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/setuptools.html
# title  : 8.57. Setuptools-82.0.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: Setuptools is a tool used to download, build, install, upgrade, and uninstall Python
#   ctx: packages. Approximate build time: less than 0.1 SBU Required disk space: 22 MB 8.57.1.
#   ctx: Installation of Setuptools Build the package:
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD

# --- block 1 --------------------------------------------------
#   ctx: Install the package:
pip3 install --no-index --find-links dist setuptools

