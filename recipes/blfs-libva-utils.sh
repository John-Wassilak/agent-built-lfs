#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page for libva-utils (the book's own
# libva.html page lists it only as an optional companion, no install steps).
# source: github.com/intel/libva-utils, tag 2.24.0 (matches this system's
#   libva-2.23.0 -- libva-utils tracks libva's ABI, not lockstep versioning).
# Rationale: operator-requested video codec/acceleration troubleshooting
# (VAAPI hardware decode on nouveau/GK104). vainfo gives an authoritative
# list of what profiles the driver actually advertises, rather than
# inferring hardware/driver decode support purely from mpv/ffmpeg trial
# and error.
set -e

mkdir build
cd build

meson setup .. \
  --prefix=/usr \
  --buildtype=release
ninja

ninja install

echo "### vainfo (requires a real DRM render node, works headless)"
vainfo 2>&1 || true
