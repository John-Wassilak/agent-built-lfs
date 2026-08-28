#!/bin/bash
# HAND-AUTHORED recipe. Not a BLFS book page -- nv-codec-headers is a dependency
# FFmpeg names in its own configure, not something the book packages.
# title  : nv-codec-headers-11.1.5.3
#
# What this is: header-only stubs for NVIDIA's NVENC (encode) and NVDEC/CUVID
# (decode) entry points. Nothing links against them; FFmpeg dlopen()s the real
# libnvidia-encode.so.1 / libnvcuvid.so.1 shipped by the driver at runtime. So
# the ONLY thing that matters is that the header API version matches what the
# installed driver actually implements.
#
# WHY 11.1.5.3 AND NOT LATEST -- this pin is load-bearing:
#   The GPU is a GTX 770 (GK104, Kepler). Kepler's last driver branch is 470.x,
#   which is EOL and will never advance. Probed on 2026-08-27 against the
#   installed 470.256.02 driver:
#       NvEncodeAPIGetMaxSupportedVersion() -> 11.1
#   Headers newer than 12.0 declare an API the driver cannot serve, and
#   nvEncOpenEncodeSessionEx() then fails at runtime with an unsupported-version
#   error -- it builds clean and dies on first use. FFmpeg 8.0's configure
#   anticipates exactly this and accepts a range of header generations:
#       configure:6912  ffnvcodec >= 12.1.14.0
#       configure:6913  ffnvcodec >= 12.0.16.1  < 12.1
#       configure:6914  ffnvcodec >= 11.1.5.3   < 12.0   <-- the one we satisfy
#       configure:6915  ffnvcodec >= 11.0.10.3  < 11.1
#       configure:6916  ffnvcodec >= 8.1.24.15  < 8.2
#   11.1.5.3 is the newest tag inside the 11.1 window, so it is the exact
#   ceiling this driver supports. Do not bump it with the usual version-drift
#   sweep; lfsmaint will flag it as stale and it must stay stale.
#
# Capability probe of the GTX 770 through this API (same date):
#   encode : H.264 only (no HEVC -- Kepler NVENC predates it)
#            max 4096x4096, 4 B-frames, B-frame-as-ref, 1 encoder engine
#            NO lookahead, NO temporal AQ, NO 10-bit, NO YUV444
#   decode : H.264 4096x4096, MPEG-2 4080x4080, VC-1 2032x2032
#            no HEVC, no VP9, no AV1
#
# Source: https://github.com/FFmpeg/nv-codec-headers/archive/refs/tags/n11.1.5.3.tar.gz
#         (save as nv-codec-headers-11.1.5.3.tar.gz in /sources)
set -e

# No configure script; PREFIX must be passed to both targets since `install`
# regenerates ffnvcodec.pc via its `all` prerequisite.
make PREFIX=/usr
make PREFIX=/usr install

echo "### installed pkg-config version"
PKG_CONFIG_PATH=/usr/lib/pkgconfig pkg-config --modversion ffnvcodec
