#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS. Required by picom for its event loop.
# Standard autotools build.
set -e

./configure --prefix=/usr --disable-static
make
make install
