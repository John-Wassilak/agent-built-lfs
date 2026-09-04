#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS. hyprshot's own dependency list names it ("to copy screenshot
# to clipboard") -- hyprshot pipes grim's PNG output straight into `wl-copy`. Only real
# dep is wayland (already built); wayland-protocols is a build-time-only dep, already
# present. Version and sha256 match Arch's own PKGBUILD (wl-clipboard 2.3.0) byte for
# byte.
set -e

meson setup --prefix=/usr --buildtype=release . build
ninja -C build install

echo "### version"
wl-copy --version 2>&1 || true
wl-paste --version 2>&1 || true
