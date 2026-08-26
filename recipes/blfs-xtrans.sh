#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in this BLFS mirror. Header-only X transport library, required by libx11's configure (discovered when libx11's build failed: 'Package xtrans not found'). Arch's official xtrans PKGBUILD as reference -- header-only, no compile step, just configure + install.
set -e

./configure $XORG_CONFIG
make install

