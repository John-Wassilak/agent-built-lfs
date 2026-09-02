#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/xsoft/firefox.html
# title  : Firefox-140.8.0esr
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: . Optional cURL-8.18.0, Doxygen-1.16.1, FFmpeg-8.0.1 (runtime, to play mov, mp3 or mp4
#   ctx: files), GeoClue-2.8.0 (runtime), liboauth-1.0.3, libproxy-0.5.12, pciutils-3.14.0
#   ctx: (runtime), Valgrind-3.26.0, Wget-1.25.0, Wireless Tools-29, and yasm-1.3.0 Editor Notes:
#   ctx: https://wiki.linuxfromscratch.org/blfs/wiki/firefox Installation of Firefox First, apply
#   ctx: a patch to fix video functionality with FFmpeg-8.0.1:
patch -Np1 -i ../firefox-140.8.0esr-ffmpeg-8.0.patch

# --- block 1 --------------------------------------------------
#   ctx: Fix building this package with glibc-2.43 and adapt the checksums:
GLSL_PTHREAD="third_party/rust/glslopt/glsl-optimizer/include/c11/threads_posix.h"
OLDSHA=`sha256sum $GLSL_PTHREAD | awk '{ print $1 }'` &&
patch -Np1 -i ../firefox-140.8.0esr-glibc-2.43.patch &&
NEWSHA=`sha256sum $GLSL_PTHREAD | awk '{ print $1 }'` &&
sed "s/$OLDSHA/$NEWSHA/" \
  -i third_party/rust/glslopt/.cargo-checksum.json

# --- block 2 --------------------------------------------------
#   ctx: Next, fix building this package with Python-3.14:
patch -Np1 -i ../firefox-140.8.0esr-python_3.14_fixes-1.patch

# --- block 3 --------------------------------------------------
#   ctx: hed by creating a mozconfig file containing the desired configuration options. A default
#   ctx: mozconfig is created below. To see the entire list of available configuration options
#   ctx: (and an abbreviated description of some of them), issue ./mach configure -- --help |
#   ctx: less. You may also wish to review the entire file and uncomment any other desired
#   ctx: options. Create the file by issuing the following command:
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
ac_add_options --enable-rust-simd

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

# --- block 4 --------------------------------------------------
#   ctx: If you are building with system ICU-78.1 or later, update one file:
sed -i '/VIRAMA = 47/a CLASS_CHARACTER,' intl/lwbrk/LineBreaker.cpp

# --- block 5 --------------------------------------------------
#   ctx: If the geolocation APIs are needed: Note The Google API Key below is specific to LFS. If
#   ctx: using these instructions for another distro, or if you intend to distribute binary
#   ctx: copies of the software using these instructions, please obtain your own key following
#   ctx: the instructions located at https://www.chromium.org/developers/how-tos/api-keys.
echo "AIzaSyDxKL42zsPjbke5O8_rPVpVrLrJ8aeE9rQ" > google-key

# --- block 6 --------------------------------------------------
#   ctx: Note If you are compiling this package in chroot you must ensure that /dev/shm is
#   ctx: mounted. If you do not do this, the Python configuration will fail with a traceback
#   ctx: report referencing /usr/lib/pythonN.N/multiprocessing/synchronize.py. As the root user,
#   ctx: run:
mountpoint -q /dev/shm || mount -t tmpfs devshm /dev/shm

# --- block 7 --------------------------------------------------
#   ctx: Compile Firefox by issuing the following commands:
export MACH_BUILD_PYTHON_NATIVE_PACKAGE_SOURCE=none &&
export MOZBUILD_STATE_PATH=${PWD}/mozbuild          &&
./mach build

# --- block 8 --------------------------------------------------
#   ctx: d them, you can run the tests by executing ./mach gtest. This will require a network
#   ctx: connection, and to be run from within an Xorg session - there is a popup dialog when it
#   ctx: fails to connect to ALSA (that does not create a failed test). One or two tests will
#   ctx: fail. To see the details of the failure(s) you will need to log the output from that
#   ctx: command so that you can review it. Now, as the root user:
export MACH_BUILD_PYTHON_NATIVE_PACKAGE_SOURCE=none &&
./mach install

# --- block 9 --------------------------------------------------
#   ctx: Empty the environment variables which were set above:
unset MACH_BUILD_PYTHON_NATIVE_PACKAGE_SOURCE
unset MOZBUILD_STATE_PATH

# --- block 10 --------------------------------------------------
#   ctx: cc and g++, primarily because of extra warnings, and is bigger. Set these environment
#   ctx: variables before you run the configure script if you wish to continue to use gcc, g++.
#   ctx: Building with GCC on i?86 is currently broken. Configuring Firefox If you use a desktop
#   ctx: environment like Gnome or KDE you may want to create a firefox.desktop file so that
#   ctx: Firefox appears in the panel's menus. As the root user:
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

