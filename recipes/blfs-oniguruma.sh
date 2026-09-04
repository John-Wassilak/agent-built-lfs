#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS. jq's regex engine (the next step) links against it; jq's own
# configure will silently build a bundled copy instead if this is missing, which is
# the thing to avoid (a private copy nothing else can share or patch). Plain autotools,
# no other dependency. Version and sha256 match Arch's own PKGBUILD (oniguruma 6.9.10)
# byte for byte.
set -e

./configure --prefix=/usr --enable-posix-api
make
make install

echo "### pkg-config"
pkg-config --modversion oniguruma 2>&1 || true
