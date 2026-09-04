#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS. hyprshot's own dependency list names it explicitly ("to parse
# and manipulate json", real usage: `hyprctl monitors -j | jq ...`). REVISED 2026-09-04:
# server already built this exact recipe (its own seq 198, "needed by hyprshot" --
# hyprshot itself was never actually reached there) against jq's bundled vendored
# oniguruma, since no system copy existed on that host; this session added a real
# system oniguruma (seq 240, just before this step) instead, on the theory that a
# private bundled copy nothing else can share is worth avoiding. Checked jq's own
# configure.ac before assuming that theory holds across both hosts: `--with-oniguruma`
# defaults to `yes`, which probes for the system library via pkg-config/AC_CHECK_LIB and
# falls back to building the shipped vendor/oniguruma copy with a notice, never a hard
# failure, if it is absent -- so this same recipe, unmodified, still works exactly as
# before on a host with no system oniguruma. Confirmed live here via `ldd`, not assumed
# from a clean configure log.
set -e

./configure --prefix=/usr --disable-maintainer-mode
make
make install

echo "### version"
jq --version 2>&1 || true
echo "### linked against system oniguruma, not a bundled copy"
ldd /usr/bin/jq | grep onig || echo "WARNING: jq is not linked against liboniguruma"
