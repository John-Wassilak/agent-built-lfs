#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/jinja2.html
# title  : 8.77. Jinja2-3.1.6
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: Jinja2 is a Python module that implements a simple pythonic template language.
#   ctx: Approximate build time: less than 0.1 SBU Required disk space: 2.7 MB 8.77.1.
#   ctx: Installation of Jinja2 Build the package:
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD

# --- block 1 --------------------------------------------------
#   ctx: Install the package:
pip3 install --no-index --find-links dist Jinja2

