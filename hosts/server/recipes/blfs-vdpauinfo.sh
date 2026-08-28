#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page for vdpauinfo.
# source: gitlab.freedesktop.org/vdpau/vdpauinfo, tag 1.5.
# Rationale: needed a real, authoritative way to confirm VDPAU decode
# capability on the NVIDIA proprietary driver (mirrors vainfo's role
# for VAAPI) -- see BUILD-REPORT.md's Phase 4 testing section. Real
# result: confirmed H264_HIGH level 51 decode capability, matching the
# exact profile that crashes under nouveau's VAAPI.
set -e

autoreconf -fi
./configure --prefix=/usr
make
make install
