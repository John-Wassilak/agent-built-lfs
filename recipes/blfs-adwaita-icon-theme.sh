#!/bin/bash
# HAND-AUTHORED recipe. BLFS carries an adwaita-icon-theme page
# (x/adwaita-icon-theme.html), but this host has no book mirror in native mode, so
# this was written by hand from the tarball's own meson.build. Prefer the book's
# version if it is ever re-derived.
#
# rationale: hicolor (built just before this) supplies the fallback *index* but
# almost no actual artwork, so GTK still finds no icon for a real name like
# "system-run" or an application's own icon. Adwaita is GTK's default theme and
# what its own widget code expects to resolve against.
#
# Version 49.0 chosen to match this build's GNOME generation rather than picking
# "newest": gsettings-desktop-schemas here is 49.1, i.e. GNOME 49. Checked that
# adwaita-icon-theme 49.1 does not exist upstream (download.gnome.org returns 404;
# 49.0 is the only 49-series release) before settling on it.
#
# Source: download.gnome.org, upstream.
#   adwaita-icon-theme-49.0.tar.xz
#   sha256 65166461d1b278aa942f59aa8d0fccf1108d71c65f372c6266e172449791755c
#
# Build-time dependency worth naming: meson.build does
#   gtk_update_icon_cache = find_program('gtk4-update-icon-cache',
#                                        'gtk-update-icon-cache', ...)
# so one of the two must already exist or configure fails. Both are present in
# this build (gtk3 and gtk4 are both installed well before this step), but that is
# the reason this cannot be ordered ahead of GTK.
#
# Pure data, shared -- no machine-specific content.
set -e

mkdir build
cd    build

meson setup .. \
      --prefix=/usr \
      --buildtype=release
ninja

ninja install

echo "### theme installed:"
ls -l /usr/share/icons/Adwaita/index.theme
echo "### icon cache:"
ls -l /usr/share/icons/Adwaita/icon-theme.cache 2>/dev/null || echo "(no cache file -- theme uses per-size dirs)"
