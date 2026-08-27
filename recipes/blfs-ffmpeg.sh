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
