#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.1-systemd book.
# source : book/13.1/chapter08/wheel.html
# title  : 8.57 Wheel-0.48.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: Wheel is a Python library that is the reference implementation of the Python wheel
#   ctx: packaging standard. Approximate build time: less than 0.1 SBU Required disk space: 768
#   ctx: KB 8.57.1 Installation of Wheel Compile Wheel with the following command:
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD

# --- block 1 --------------------------------------------------
#   ctx: Install Wheel with the following command:
pip3 install --no-index --find-links dist wheel

