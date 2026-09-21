#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/x/libxcb.html
# title  : libxcb-1.17.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: pace required: 30 MB (with tests, add 62 MB for doxygen docs) Estimated build time: 0.2
#   ctx: SBU (with tests, add 1.4 SBU for doxygen docs) libxcb Dependencies Required
#   ctx: libXau-1.0.12 and xcb-proto-1.17.0 Recommended libXdmcp-1.1.5 (required for Mesa-25.3.5)
#   ctx: Optional Doxygen-1.16.1 (to generate API documentation) and libxslt-1.1.45 Installation
#   ctx: of libxcb Install libxcb by running the following commands:
./configure $XORG_CONFIG      \
            --without-doxygen \
            --docdir='${datadir}'/doc/libxcb-1.17.0 &&
LC_ALL=en_US.UTF-8 make

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user:
make install

# --- block 2 --------------------------------------------------
#   ctx: If the package was built as a non-root user, the installed documentation is now owned by
#   ctx: this user. As the root user, fix the ownership:
chown -Rv root:root $XORG_PREFIX/share/doc/libxcb-1.17.0

