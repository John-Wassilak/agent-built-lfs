#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/general/shared-mime-info.html
# title  : shared-mime-info-2.5.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: SBU (with tests) Shared Mime Info Dependencies Required GLib-2.88.3 and libxml2-2.15.3
#   ctx: Optional git-2.55.0 (for tests), and xmlto-0.0.29 Note An Internet connection is needed
#   ctx: for some tests of this package. The system certificate store may need to be set up with
#   ctx: make-ca-1.16.1 before testing this package. Installation of Shared Mime Info Install
#   ctx: Shared Mime Info by running the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=/usr         \
            --buildtype=release   \
            -D update-mimedb=true \
            -D build-tests=false  \
            -D build-spec=false   \
            .. &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: Now, as the root user:
ninja install

