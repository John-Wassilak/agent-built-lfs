#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/multimedia/mpv.html
# title  : mpv-0.41.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: Vulkan-Loader-1.4.341.0 Optional Input Drivers and Libraries libdvdcss-1.5.0,
#   ctx: libdvdread-7.0.1, libdvdnav-7.0.0, and libbluray Optional Audio Output Drivers and
#   ctx: Libraries pipewire-1.6.0, sdl2-compat-2.32.64, JACK, and OpenAL Optional Video Output
#   ctx: Drivers and Libraries libcaca and SVGAlib Optional (for documentation) docutils-0.22.4
#   ctx: Installation of mpv Install mpv by running the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=/usr       \
            --buildtype=release \
            -D x11=enabled      \
            ..                  &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
ninja install

# --- block 2 --------------------------------------------------
#   ctx: r hierarchy and desktop files into the /usr/share/applications hierarchy. You can
#   ctx: improve system performance and memory usage by updating
#   ctx: /usr/share/icons/hicolor/index.theme and /usr/share/applications/mimeinfo.cache. To
#   ctx: perform the update you must have GTK-3.24.51 installed (for the icon cache) and
#   ctx: desktop-file-utils-0.28 (for the desktop cache) and issue the following commands as the
#   ctx: root user:
#   TAGS: admon:note   [DISABLED - review]
# gtk-update-icon-cache -qtf /usr/share/icons/hicolor &&
# update-desktop-database -q

