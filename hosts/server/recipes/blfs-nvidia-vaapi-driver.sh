#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS/SLFS/GLFS page covers this package.
# source : https://github.com/elFarto/nvidia-vaapi-driver (v0.0.18, 2026-08-31)
# title  : nvidia-vaapi-driver-0.0.18
#
# Why this is a host recipe and not shared: it exists solely to serve a proprietary
# NVIDIA GPU. `laptop` is Intel HD 520 on i915/iris and has a working mesa VA-API
# driver already, so this file would be dead weight there. Root CLAUDE.md's test --
# "anything naming a GPU vendor" -- puts it here.
#
# rationale: Firefox on Linux does hardware video decode ONLY through VA-API; it has no
# VDPAU path. The NVIDIA 470 driver ships VDPAU and no VA-API driver at all, so libva
# had nothing to load but /usr/lib/dri/nouveau_drv_video.so (a symlink into
# libgallium), which cannot drive a card bound to the proprietary driver with nouveau
# blacklisted. Measured before installing this: `vainfo` failed with
# "vaGetDriverNames() failed", and Firefox 153.2.0esr's about:support reported
# HARDWARE_VIDEO_DECODING unavailable with every codec at SWDEC. This library
# implements VA-API on top of NVDEC, which the 470 driver does expose and which this
# host's ffmpeg is already built against (--enable-nvdec/cuvid, see blfs-ffmpeg.sh).
#
# WHAT THIS GPU CAN ACTUALLY DECODE, which bounds the benefit: the GTX 770 is Kepler
# GK104. `vdpauinfo` enumerates MPEG1, MPEG2_SIMPLE/MAIN, H264_BASELINE/MAIN/HIGH to
# level 51, and VC1_SIMPLE/MAIN/ADVANCED; VP9, HEVC and AV1 all report
# "--- not supported ---". NVDEC is the same silicon block, so this driver buys
# hardware H.264 (plus MPEG2/VC1) and nothing more. Sites serving VP9 or AV1 -- which
# is most of YouTube by default -- will still decode in software no matter what is
# configured here. That is a hardware ceiling, not a packaging gap.
#
# Build dependencies, all already present and checked before the first build:
#   egl 1.5 (libglvnd), ffnvcodec 11.1.5.3 (blfs-nv-codec-headers; the driver needs
#   >= 11.1.5.1, so that recipe's immovable pin is comfortably inside the range),
#   libdrm 2.4.134, libva 1.24.0 (needs >= 1.8.0), threads.
#
# gstreamer-codecparsers-1.0 is NOT installed and is deliberately not added. meson
# treats it as optional (`required: false`) and it only enables VP9, which this GPU
# cannot decode anyway -- pulling in the whole GStreamer stack to enable a codec the
# silicon does not support would be pure cost.
#
# The install path is not hardcoded: meson asks pkg-config for libva's own `driverdir`
# (`pkg-config --variable=driverdir libva` -> /usr/lib/dri), so the .so lands exactly
# where libva searches.
#
# nvidia-drm.modeset=1 is a hard runtime requirement of this driver. It was already
# satisfied here by /etc/modprobe.d/nvidia-modeset.conf ("options nvidia-drm
# modeset=1"), confirmed live via /sys/module/nvidia_drm/parameters/modeset = Y, so no
# kernel command line change and no reboot were needed. Anything that re-images this
# host must keep that file -- see BOOTSTRAP.md's overlay step.
#
# The runtime environment and the Firefox prefs this driver needs are NOT set here;
# they belong to the session, not the build. They are in
# hosts/server/overlay/home/john/.xinitrc and the notes in BUILD-REPORT.md.
set -e

mkdir build
cd build

meson setup --prefix=/usr --buildtype=release ..
ninja

ninja install

echo "### installed driver"
ls -l /usr/lib/dri/nvidia_drv_video.so 2>&1 || true
