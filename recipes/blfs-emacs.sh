#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/postlfs/emacs.html
# title  : Emacs-30.2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: , libpng-1.6.55, librsvg-2.61.4, libseccomp-2.6.0, libwebp-1.6.0, libxml2-2.15.1, MIT
#   ctx: Kerberos V5-1.22.2, Valgrind-3.26.0, intlfonts, libungif, libotf, and m17n-lib - to
#   ctx: correctly display such complex scripts as Indic and Khmer, and also for scripts that
#   ctx: require Arabic shaping support (Arabic and Farsi), mailutils, and libXaw3d Installation
#   ctx: of Emacs Install Emacs by running the following commands:
./configure --prefix=/usr --with-xpm=ifavailable &&
make

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. If make succeeds, you can test the result
#   ctx: by running src/emacs -Q, which is the program that will be installed, with its auxiliary
#   ctx: files. This should start and display the application opening screen. Now, as the root
#   ctx: user:
make install &&
chown -v -R root:root /usr/share/emacs/30.2

# --- block 2 --------------------------------------------------
#   ctx: Note This package installs icon files into the /usr/share/icons/hicolor hierarchy and
#   ctx: you can improve system performance and memory usage by updating
#   ctx: /usr/share/icons/hicolor/index.theme. To perform the update you must have GTK-3.24.51
#   ctx: installed and issue the following command as the root user:
#   TAGS: admon:note   [DISABLED - review]
# gtk-update-icon-cache -qtf /usr/share/icons/hicolor

