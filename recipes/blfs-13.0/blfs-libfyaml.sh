#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/libfyaml.html
# title  : libfyaml-0.9.4
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: 2.5 (for YAML 0.1 support) Optional git-2.53.0, sphinx-9.1.0 and sphinx_rtd_theme-3.1.0
#   ctx: (for documentation), docker, jq, and check (for additional tests) Note An Internet
#   ctx: connection is needed for some tests of this package. The system certificate store may
#   ctx: need to be set up with make-ca-1.16.1 before testing this package. Installation of
#   ctx: libfyaml Install libfyaml by running the following commands:
./configure --prefix=/usr --disable-static &&
make

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user:
make install

