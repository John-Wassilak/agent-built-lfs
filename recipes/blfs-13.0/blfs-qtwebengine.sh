#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/x/qtwebengine.html
# title  : QtWebEngine-6.10.2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: version, with the side effect of increasing build and installed disk space and build
#   ctx: time. either alsa-lib-1.2.15.3 or PulseAudio-17.0 (or both), FFmpeg-8.0.1, ICU-78.2,
#   ctx: libwebp-1.6.0, libxslt-1.1.45, Opus-1.6.1, and pipewire-1.6.0 Optional MIT Kerberos
#   ctx: V5-1.22.2, Poppler-26.02.0, jsoncpp, libsrtp, and snappy Installation of qtwebengine
#   ctx: First, make a fix to be compatible with glibc-2.43 and later:
sed -e '/ifndef SYS_SECCOMP/,+2 d' \
    -i src/3rdparty/chromium/sandbox/linux/system_headers/linux_seccomp.h

# --- block 1 --------------------------------------------------
#   ctx: Install qtwebengine by running the following commands:
mkdir build &&
cd    build &&

cmake -D CMAKE_MESSAGE_LOG_LEVEL=STATUS             \
      -D QT_FEATURE_webengine_system_ffmpeg=ON      \
      -D QT_FEATURE_webengine_system_icu=ON         \
      -D QT_FEATURE_webengine_proprietary_codecs=ON \
      -D QT_FEATURE_webengine_webrtc_pipewire=ON    \
      -D QT_BUILD_EXAMPLES_BY_DEFAULT=OFF           \
      -D QT_GENERATE_SBOM=OFF                       \
      -G Ninja ..                                   &&
ninja

# --- block 2 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
ninja install

