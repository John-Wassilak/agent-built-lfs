#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/glm.html
# title  : GLM-1.0.3
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: m. Package Information Download (HTTP):
#   ctx: https://github.com/g-truc/glm/archive/1.0.3/glm-1.0.3.tar.gz Download MD5 sum:
#   ctx: 2192069d8d0091ff1cca041cdcdc85fe Download size: 4.4 MB Estimated disk space required: 25
#   ctx: MB Estimated build time: less than 0.1 SBU Installation of GLM Note This package is
#   ctx: unusual as it includes its functionality in header files. We just copy them into
#   ctx: position. As the root user:
cp -r glm /usr/include/ &&
cp -r doc /usr/share/doc/glm-1.0.3

