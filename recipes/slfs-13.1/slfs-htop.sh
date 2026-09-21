#!/bin/bash
# CANDIDATE recipe extracted from the SLFS 13.1 book.
# source : book/slfs-13.1/general/htop.html
# title  : htop-3.5.3
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: Introduction to htop The htop package provides a TUI [1] system monitor and has become
#   ctx: well-known for its ease of use and comprehensive features. Download:
#   ctx: https://github.com/htop-dev/htop/releases/download/3.5.3/htop-3.5.3.tar.xz htop
#   ctx: Dependencies Optional lm-sensors, lsof, and strace-7.1 Installation of htop Install htop
#   ctx: by running the following commands:
./configure --prefix=/usr &&
make

# --- block 1 --------------------------------------------------
#   ctx: Now, as the root user:
make pixmapdir=/usr/share/icons/hicolor/128x128/apps install

