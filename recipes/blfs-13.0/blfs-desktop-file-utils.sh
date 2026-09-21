#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/desktop-file-utils.html
# title  : desktop-file-utils-0.28
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: k space required: 1.2 MB Estimated build time: less than 0.1 SBU Desktop File Utils
#   ctx: Dependencies Required GLib-2.86.4 Optional Emacs-30.2 Installation of Desktop File Utils
#   ctx: Warning If you are upgrading from a previous version of desktop-file-utils that used the
#   ctx: Autotools method of installing and configuring the package, you must remove the
#   ctx: desktop-file-edit symlink by using the following commands.
rm -fv /usr/bin/desktop-file-edit

# --- block 1 --------------------------------------------------
#   ctx: Install Desktop File Utils by running the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release .. &&
ninja

# --- block 2 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
ninja install

# --- block 3 --------------------------------------------------
#   ctx: and XDG_DATA_DIRS, respectively. The GNOME, KDE and XFCE environments respect these
#   ctx: settings. When a package installs a .desktop file to a location in one of the base data
#   ctx: directories, the database that maps MIME-types to available applications can be updated.
#   ctx: For instance, the cache file at /usr/share/applications/mimeinfo.cache can be rebuilt by
#   ctx: executing the following command as the root user:
install -vdm755 /usr/share/applications &&
update-desktop-database /usr/share/applications

