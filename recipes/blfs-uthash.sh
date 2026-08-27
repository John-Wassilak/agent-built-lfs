#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS. Required by picom, which meson-checks for
# uthash.h via a plain header existence test, not a pkg-config package
# -- header-only library, nothing to compile or link.
set -e

install -v -d /usr/include
install -v -m644 src/*.h /usr/include/
