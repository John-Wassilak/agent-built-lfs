#!/bin/bash
# HAND-AUTHORED recipe from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/multimedia/ffmpeg.html
# title  : FFmpeg-8.0.1
# rationale: Recommended codec deps (dav1d, libaom, libass, fdk-aac, freetype2,
# lame, libvorbis, libvpx, opus, svt-av1, x264, x265, nasm) and desktop deps
# (alsa-lib, libva, sdl2-compat) are all already built (tiers 2/6/7/11/12).
# openssl is already present from the base LFS build. Follows the book's
# documented ./configure flags as-is -- libplacebo support not enabled since
# the book's own recipe doesn't flag it on by default.
#
# Rebuilt 2026-08-26 with --enable-vdpau added, as part of the X11/
# NVIDIA migration's real VDPAU verification (see BUILD-REPORT.md's
# Phase 4 testing). Real finding: `ffmpeg -hwaccels` never listed vdpau
# at all before this -- confirmed via `-hwaccel vdpau` failing with a
# generic "Device creation failed: -12" / "Cannot allocate memory"
# (a misleading error; the real cause was simply that libavutil's
# hwcontext_vdpau.c was never compiled in). mpv's own -D vdpau=enabled
# rebuild (blfs-mpv.sh) wasn't sufficient on its own -- both had to be
# rebuilt, since mpv delegates the actual VDPAU device management to
# this shared library.
#
# Rebuilt 2026-08-27 with --enable-ffnvcodec/nvenc/nvdec/cuvid/cuda, which
# require blfs-nv-codec-headers (pinned at 11.1.5.3 -- see that recipe for why
# the pin cannot move). This turns on h264_nvenc (GPU H.264 encode) and
# h264/mpeg2/vc1 NVDEC decode on the GTX 770. Verified BEFORE building, by
# probing the driver directly rather than trusting the spec sheet: the 470.256.02
# driver reports NVENC API 11.1, and a real nvEncOpenEncodeSessionEx() on the
# GTX 770 succeeded and enumerated H.264 encode support.
#
# Deliberately NOT enabled: --enable-cuda-nvcc and --enable-libnpp. Those pull in
# the full CUDA toolkit to compile the scale_cuda / scale_npp filter kernels.
# Not worth it here -- CPU-side swscale was measured at ~2% of this box's
# transcode cost (1920x960 -> 1280x720 with pad: 2.16x without the pad filter
# vs 2.12x with it), so there is nothing to reclaim by moving scaling onto the
# GPU. Decode and encode are the expensive halves and both are covered above.
set -e

patch -Np1 -i ../ffmpeg-8.0.1-chromium_method-1.patch

sed -e '/adaptive/c\ param->aq_mode = 0;' \
    -i libavcodec/libsvtav1.c

./configure --prefix=/usr \
  --enable-gpl \
  --enable-version3 \
  --enable-nonfree \
  --disable-static \
  --enable-shared \
  --disable-debug \
  --enable-libaom \
  --enable-libass \
  --enable-libfdk-aac \
  --enable-libfreetype \
  --enable-libmp3lame \
  --enable-libopus \
  --enable-libvorbis \
  --enable-libvpx \
  --enable-libx264 \
  --enable-libx265 \
  --enable-openssl \
  --enable-libdav1d \
  --enable-libsvtav1 \
  --enable-vdpau \
  --enable-ffnvcodec \
  --enable-nvenc \
  --enable-nvdec \
  --enable-cuvid \
  --enable-cuda \
  --ignore-tests=enhanced-flv-av1,enhanced-flv-multitrack \
  --docdir=/usr/share/doc/ffmpeg-8.0.1

make

gcc tools/qt-faststart.c -o tools/qt-faststart

make install
install -v -m755 tools/qt-faststart /usr/bin
install -v -m755 -d /usr/share/doc/ffmpeg-8.0.1
install -v -m644 doc/*.txt /usr/share/doc/ffmpeg-8.0.1

echo "### version"
ffmpeg -version 2>&1 | head -1 || true
