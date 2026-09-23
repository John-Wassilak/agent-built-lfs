#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/xsoft/gimp.html
# title  : Gimp-3.0.6
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: dblatex (for PDF docs), pngnq and pngcrush to optimize the png files, but see the note
#   ctx: on the help download above Editor Notes:
#   ctx: https://wiki.linuxfromscratch.org/blfs/wiki/gimp Installation of Gimp If upgrading from
#   ctx: a previous Gimp-3 installation, as the root user, remove some files and directories from
#   ctx: the old installation or the build system may mistakenly pick them up, causing a build
#   ctx: failure:
rm -rf /usr/{lib,share}/gimp/3.0 &&
rm -f  /usr/share/gir-1.0/Gimp-3.0.gir &&
rm -f  /usr/lib/girepository-1.0/Gimp-3.0.typelib &&
rm -f  /usr/lib/libgimp*-3.0.so*

# --- block 1 --------------------------------------------------
#   ctx: First, fix some security vulnerabilities identified upstream:
patch -Np1 -i ../gimp-3.0.6-security_fixes-1.patch

# --- block 2 --------------------------------------------------
#   ctx: Install Gimp by running the following commands:
mkdir gimp-build &&
cd    gimp-build &&

meson setup ..            \
      --prefix=/usr       \
      --buildtype=release \
      -D headless-tests=disabled &&
ninja

# --- block 3 --------------------------------------------------
#   ctx: To test the results (requires a terminal in a graphical environment) issue: ninja test.
#   ctx: Three tests, gimp:app / save-and-export, gimp:app / single-window-mode, and gimp:app /
#   ctx: ui, are known to fail. Now, as the root user:
ninja install &&

if [ -d /tmp/gimp ] && [ "$(stat -c %u /tmp/gimp)" = 0 ]; then
  rm -rf /tmp/gimp
fi

# --- block 4 --------------------------------------------------
#   ctx: r hierarchy and desktop files into the /usr/share/applications hierarchy. You can
#   ctx: improve system performance and memory usage by updating
#   ctx: /usr/share/icons/hicolor/index.theme and /usr/share/applications/mimeinfo.cache. To
#   ctx: perform the update you must have GTK-3.24.51 installed (for the icon cache) and
#   ctx: desktop-file-utils-0.28 (for the desktop cache) and issue the following commands as the
#   ctx: root user:
#   TAGS: admon:note   [DISABLED - review]
# gtk-update-icon-cache -qtf /usr/share/icons/hicolor &&
# update-desktop-database -q

# --- block 5 --------------------------------------------------
#   ctx: Installation of Gimp-Help The gimp-help tarball contains images and English text help
#   ctx: for help files, together with translations. If you wish to install local copies of the
#   ctx: help files to read offline, unpack the gimp-help tarball and change into the root of the
#   ctx: newly created source tree.
#   REVIEWED [drop]: The book's condition: 'If you wish to install local copies of the help files to read offline, unpack the gimp-help tarball'. gimp-help-3.0.2 is an Additional Download (123 MB, 74 MB installed) and was not fetched; Gimp opens its online manual when the local one is absent.
# tar -xf ../../gimp-help-3.0.2.tar.bz2 &&
# cd gimp-help-3.0.2
# 
# sed -i 's/import libxml2//' configure &&
# 
# ALL_LINGUAS="en" \
# ./configure --prefix=/usr

# --- block 6 --------------------------------------------------
#   ctx: Building non-English languages is only possible with the libxml2 Python 3 module, which
#   ctx: is deprecated and no longer enabled in the BLFS libxml2 build. Now build the help files:
#   REVIEWED [drop]: Builds the gimp-help tree unpacked by block 5, dropped for the same reason.
# make

# --- block 7 --------------------------------------------------
#   ctx: Issue the following commands as the root user to install the help files:
#   REVIEWED [drop]: Installs the gimp-help tree built by block 6, dropped for the same reason.
# make install &&
# chown -R root:root /usr/share/gimp/3.0/help

