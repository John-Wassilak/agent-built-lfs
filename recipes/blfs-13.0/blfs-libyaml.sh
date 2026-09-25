#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/libyaml.html
# title  : libyaml-0.2.5
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: Information Download (HTTP):
#   ctx: https://github.com/yaml/libyaml/releases/download/0.2.5/yaml-0.2.5.tar.gz Download MD5
#   ctx: sum: bb15429d8fb787e7d3f1c83ae129a999 Download size: 596 KB Estimated disk space
#   ctx: required: 6.4 MB (with tests) Estimated build time: less than 0.1 SBU (with tests)
#   ctx: libyaml Dependencies Optional Doxygen-1.16.1 Installation of libyaml Install libyaml by
#   ctx: running the following commands:
./configure --prefix=/usr --disable-static &&
make

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user:
make install

