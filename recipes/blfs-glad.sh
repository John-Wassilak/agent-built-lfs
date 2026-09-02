#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/glad.html
# title  : Glad-2.0.8
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ): https://github.com/Dav1dde/glad/archive/v2.0.8/glad-2.0.8.tar.gz Download MD5 sum:
#   ctx: 028c39d581e6b53e53871f1dc21cf442 Download size: 632 KB Estimated disk space required: 14
#   ctx: MB Estimated build time: less than 0.1 SBU Glad Dependencies Optional (required to run
#   ctx: the tests) pytest-9.0.2, rustc-1.93.1, Xorg Libraries, glfw, and WINE Installation of
#   ctx: Glad Install Glad by running the following commands:
pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD

# --- block 1 --------------------------------------------------
#   ctx: This package comes with a test suite, but it cannot be run without installing the
#   ctx: external dependencies listed above. Now, as the root user:
pip3 install --no-index --find-links dist --no-user glad2

