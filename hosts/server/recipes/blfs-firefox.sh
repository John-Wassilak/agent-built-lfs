#!/bin/bash
# HAND-AUTHORED recipe -- host-specific fork of the shared recipes/blfs-firefox.sh.
# source : book/blfs-13.1/xsoft/firefox.html
# title  : Firefox-153.2.0esr
#
# Re-read against BLFS 13.1 on 2026-09-21, replacing the 140.8.0esr fork this file
# carried. 13.1 moves Firefox from the 140 ESR line to 153.2.0esr, and the page's
# command set shrank accordingly -- every block below is the 13.1 page's, in its
# order, with exactly two host deltas marked in the mozconfig.
#
# Four blocks the 140.8.0esr fork carried are GONE from the 13.1 page and are
# deliberately not carried forward. Each was a version-specific workaround whose
# patch does not exist for 153.2.0esr:
#   - firefox-140.8.0esr-ffmpeg-8.0.patch (video with FFmpeg 8);
#   - firefox-140.8.0esr-glibc-2.43.patch, plus the glslopt .cargo-checksum.json
#     sha256 fixup that existed only to keep that patch from breaking the vendored
#     crate's checksum;
#   - firefox-140.8.0esr-python_3.14_fixes-1.patch;
#   - `sed -i '/VIRAMA = 47/a CLASS_CHARACTER,' intl/lwbrk/LineBreaker.cpp`, the
#     system-ICU-78.1 fixup.
# Verified by extracting every <pre> block from the 13.1 page: it references no
# .patch file at all, and its only download is firefox-153.2.0esr.source.tar.xz.
#
# CAUTION on the 140.14.0esr tarball: BLFS 13.1's wget-list contains BOTH
# firefox-153.2.0esr.source.tar.xz and firefox-140.14.0esr.source.tar.xz. The
# latter belongs to general/spidermonkey.html, which builds its JS engine from an
# ESR tarball, NOT to this page. `lfsmaint drift` matched installed firefox against
# it and reported the book version as 140.14.0esr, which is wrong for this package
# -- the firefox page says 153.2.0esr and that is what packages.py seq 192 pins.
#
# Host delta 1: --enable-audio-backends=alsa is uncommented. Carried from the
# previous fork. The book ships it commented for PulseAudio users.
#
# Host delta 2: --enable-rust-simd stays commented out. On 140.8.0esr it was a real
# build failure on this host's Rust-1.97.1 -- "error[E0599]: no method named
# `select` found for struct `Mask<T, N>`" compiling the vendored encoding_rs
# v0.8.35, whose use of the still-unstable core::simd API predates that Rust.
# Firefox 153.2.0esr vendors a newer encoding_rs and this may well build now, but
# that cannot be established without a full build, and the option is purely a
# text-decoding performance optimization. Kept off for the first 153 build as the
# conservative choice; re-testing it is a one-line change and worth doing once
# 153.2.0esr is known to build here.
set -e

# --- block 0 --------------------------------------------------
#   mozconfig (book's, with this host's two deltas marked inline)
cat > mozconfig << "EOF"
# If you have a multicore machine, all cores will be used by default.

# If you have installed (or will install) wireless-tools, and you wish
# to use geolocation web services, comment out this line
ac_add_options --disable-necko-wifi

# Comment out the following line if you wish not to use Google's Location
# Service (GLS).  Note that if Geoclue is installed and configured to use
# GLS (as the BLFS instruction does), Firefox can access GLS via Geoclue
# anyway.  On the other hand if Geoclue is not installed (or not properly
# configured) and this line is commented out, the website requiring a
# location service will not function properly.
ac_add_options --with-google-location-service-api-keyfile=$PWD/google-key

# If you wish to use libproxy to determine proxy server information, you will
# need to install the libproxy package and then uncomment the option below:
#ac_add_options --enable-libproxy

# Uncomment the following option if you have not installed PulseAudio and
# want to use alsa instead
ac_add_options --enable-audio-backends=alsa

# Comment out following options if you have not installed
# recommended dependencies:
ac_add_options --with-system-av1
ac_add_options --with-system-icu
ac_add_options --with-system-libevent
ac_add_options --with-system-libvpx
ac_add_options --with-system-nspr
ac_add_options --with-system-nss
ac_add_options --with-system-webp

# Firefox provides a copy of dav1d if it has not been installed. If you have
# not installed nasm and ffmpeg, uncomment the following line:
#ac_add_options --disable-av1

# You cannot distribute the binary if you do this.
ac_add_options --enable-official-branding

# Stripping is now enabled by default.
# Uncomment these lines if you need to run a debugger:
#ac_add_options --disable-strip
#ac_add_options --disable-install-strip

# Disabling debug symbols makes the build much smaller and a little
# faster. Comment this if you need to run a debugger.
ac_add_options --disable-debug-symbols

# The BLFS editors recommend not changing anything below this line:
ac_add_options --prefix=/usr
ac_add_options --enable-application=browser
ac_add_options --disable-crashreporter
ac_add_options --disable-updater

# Enabling the tests will use a lot more space and significantly
# increase the build time, for no obvious benefit.
ac_add_options --disable-tests

# This enables SIMD optimization in the shipped encoding_rs crate.
# Dropped on this host -- see this recipe's header.
#ac_add_options --enable-rust-simd

ac_add_options --enable-system-ffi
ac_add_options --enable-system-pixman

ac_add_options --with-system-jpeg
ac_add_options --with-system-png
ac_add_options --with-system-zlib

# Sandboxing works well on x86_64 but might cause issues on other
# platforms, e.g. i686.
[ $(uname -m) != x86_64 ] && ac_add_options --disable-sandbox

# Using sandboxed wasm libraries has been moved to all builds instead
# of only mozilla automation builds. It requires extra llvm packages
# and was reported to seriously slow the build. Disable it.
ac_add_options --without-wasm-sandboxed-libraries

# The following option unsets Telemetry Reporting. With the Addons Fiasco,
# Mozilla was found to be collecting user's data, including saved passwords and
# web form data, without users consent. Mozilla was also found shipping updates
# to systems without the user's knowledge or permission.
# As a result of this, use the following command to permanently disable
# telemetry reporting in Firefox.
unset MOZ_TELEMETRY_REPORTING

mk_add_options MOZ_OBJDIR=@TOPSRCDIR@/firefox-build-dir

# By default firefox will attempt to use the window class firefox-default on
# launch. This makes the icon not work properly because wayland does not
# support the X11 property  class header. Change the remoting name to fix this.
# This is also reflected in the .desktop file where StartupWMClass is set to
# firefox.
MOZ_APP_REMOTINGNAME=firefox
EOF

# --- block 1 --------------------------------------------------
#   Google Location Service key (the book's LFS-specific key)
echo "AIzaSyDxKL42zsPjbke5O8_rPVpVrLrJ8aeE9rQ" > google-key

# --- block 2 --------------------------------------------------
#   /dev/shm must be a mountpoint or Python's multiprocessing fails
mountpoint -q /dev/shm || mount -t tmpfs devshm /dev/shm

# --- block 3 --------------------------------------------------
#   compile
export MACH_BUILD_PYTHON_NATIVE_PACKAGE_SOURCE=none &&
export MOZBUILD_STATE_PATH=${PWD}/mozbuild          &&
./mach build

# --- block 4 --------------------------------------------------
#   install
export MACH_BUILD_PYTHON_NATIVE_PACKAGE_SOURCE=none &&
./mach install

# --- block 5 --------------------------------------------------
#   empty the build environment variables set above
unset MACH_BUILD_PYTHON_NATIVE_PACKAGE_SOURCE
unset MOZBUILD_STATE_PATH

# --- block 6 --------------------------------------------------
#   desktop entry and icon
mkdir -pv /usr/share/applications &&
mkdir -pv /usr/share/pixmaps      &&

MIMETYPE="text/xml;text/mml;text/html;"                            &&
MIMETYPE+="application/xhtml+xml;application/vnd.mozilla.xul+xml;" &&
MIMETYPE+="x-scheme-handler/http;x-scheme-handler/https"           &&

cat > /usr/share/applications/firefox.desktop << EOF &&
[Desktop Entry]
Encoding=UTF-8
Name=Firefox Web Browser
Comment=Browse the World Wide Web
GenericName=Web Browser
Exec=firefox %u
Terminal=false
Type=Application
Icon=firefox
Categories=GNOME;GTK;Network;WebBrowser;
MimeType=$MIMETYPE
StartupNotify=true
StartupWMClass=firefox
EOF

unset MIMETYPE &&

ln -sfv /usr/lib/firefox/browser/chrome/icons/default/default128.png \
        /usr/share/pixmaps/firefox.png
