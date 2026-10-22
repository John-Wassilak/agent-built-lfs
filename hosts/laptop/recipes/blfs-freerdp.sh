#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/xsoft/freerdp.html
# title  : FreeRDP-3.22.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: xsl-nons-1.79.2, Fuse-3.18.1, JSON-C-0.18, MIT Kerberos V5-1.22.2, libusb-1.0.29,
#   ctx: libxkbcommon-1.13.1, and Wayland-1.24.0 Optional Cups-2.4.16, faac-1.31.1, FAAD2-2.11.2,
#   ctx: fdk-aac-2.0.3, LAME-3.100, Linux-PAM-1.7.2, PulseAudio-17.0, SDL3-3.4.0 and SDL_ttf,
#   ctx: cJSON, GSM, ocl-icd, mbedTLS, openh264, pcsclite, soxr, and uriparser Installation of
#   ctx: FreeRDP Install FreeRDP by running the following commands:
mkdir build &&
cd    build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr   \
      -D CMAKE_SKIP_INSTALL_RPATH=ON \
      -D CMAKE_BUILD_TYPE=Release    \
      -D WITH_CAIRO=ON               \
      -D WITH_CLIENT_SDL2=OFF        \
      -D WITH_DSP_FFMPEG=ON          \
      -D WITH_FFMPEG=ON              \
      -D WITH_CUPS=OFF               \
      -D WITH_KRB5=OFF               \
      -D WITH_PCSC=OFF               \
      -D WITH_SERVER=ON              \
      -D WITH_SERVER_CHANNELS=ON     \
      -D DOCBOOKXSL_DIR=/usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2 \
      -W no-dev                      \
      -G Ninja ..                    &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
ninja install

