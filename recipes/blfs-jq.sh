#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS. Needed by hyprshot (JSON parsing of hyprctl
# output) -- operator-requested alongside alacritty. Release tarball (not
# a plain GitHub source archive) bundles a full vendored oniguruma copy
# under vendor/oniguruma -- confirmed present, not an empty submodule
# stub, before relying on it; oniguruma isn't installed system-wide, so
# jq's own ./configure builds its vendored copy automatically.
set -e

./configure --prefix=/usr --disable-maintainer-mode
make

make install

echo "### version"
jq --version 2>&1 || true
