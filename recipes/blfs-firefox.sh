#!/bin/bash
# HAND-AUTHORED recipe from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/xsoft/firefox.html
# title  : Firefox-140.8.0esr
# rationale: Required: Cbindgen, GTK3, libnotify, libarchive, LLVM+clang,
# nodejs, PulseAudio, startup-notification (all built by this point in tier
# 15). Recommended: dav1d, ICU, libaom, libevent, libvpx, libwebp, nasm, nss
# (all built). The Google API key below is the placeholder key the book
# itself documents for exactly this purpose, not a private credential.
# Largest single build in this whole project alongside LLVM (13 SBU
# estimated); expect this to take a while.
set -e

# Real bug found and fixed (2026-08-27): rustc/cargo live at
# /opt/rustc/bin, put on PATH for interactive shells via
# /etc/profile.d (see blfs-rust.sh's pathprepend line) -- but this
# recipe was first run headlessly (systemd-run, for an overnight
# build with no login shell involved), which never sources
# profile.d, so configure failed with "Rust compiler not found" even
# though it's installed. Exporting it here makes the recipe correct
# regardless of how/where it's invoked.
export PATH="/opt/rustc/bin:$PATH"

patch -Np1 -i ../firefox-140.8.0esr-ffmpeg-8.0.patch

GLSL_PTHREAD="third_party/rust/glslopt/glsl-optimizer/include/c11/threads_posix.h"
OLDSHA=$(sha256sum "$GLSL_PTHREAD" | awk '{ print $1 }')
patch -Np1 -i ../firefox-140.8.0esr-glibc-2.43.patch
NEWSHA=$(sha256sum "$GLSL_PTHREAD" | awk '{ print $1 }')
sed "s/$OLDSHA/$NEWSHA/" -i third_party/rust/glslopt/.cargo-checksum.json

patch -Np1 -i ../firefox-140.8.0esr-python_3.14_fixes-1.patch

cat > mozconfig << "EOF"
ac_add_options --disable-necko-wifi
ac_add_options --with-google-location-service-api-keyfile=$PWD/google-key
ac_add_options --with-system-av1
ac_add_options --with-system-icu
ac_add_options --with-system-libevent
ac_add_options --with-system-libvpx
ac_add_options --with-system-nspr
ac_add_options --with-system-nss
ac_add_options --with-system-webp
ac_add_options --enable-official-branding
ac_add_options --disable-debug-symbols
ac_add_options --prefix=/usr
ac_add_options --enable-application=browser
ac_add_options --disable-crashreporter
ac_add_options --disable-updater
ac_add_options --disable-tests
ac_add_options --enable-rust-simd
ac_add_options --enable-system-ffi
ac_add_options --enable-system-pixman
ac_add_options --with-system-jpeg
ac_add_options --with-system-png
ac_add_options --with-system-zlib
[ $(uname -m) != x86_64 ] && ac_add_options --disable-sandbox
ac_add_options --without-wasm-sandboxed-libraries
unset MOZ_TELEMETRY_REPORTING
mk_add_options MOZ_OBJDIR=@TOPSRCDIR@/firefox-build-dir
MOZ_APP_REMOTINGNAME=firefox
EOF

sed -i '/VIRAMA = 47/a CLASS_CHARACTER,' intl/lwbrk/LineBreaker.cpp

echo "AIzaSyDxKL42zsPjbke5O8_rPVpVrLrJ8aeE9rQ" > google-key

mountpoint -q /dev/shm || mount -t tmpfs devshm /dev/shm

export MACH_BUILD_PYTHON_NATIVE_PACKAGE_SOURCE=none
export MOZBUILD_STATE_PATH=${PWD}/mozbuild
./mach build

./mach install
unset MACH_BUILD_PYTHON_NATIVE_PACKAGE_SOURCE
unset MOZBUILD_STATE_PATH

echo "### version"
firefox --version 2>&1 || true
