#!/bin/bash
# HAND-AUTHORED recipe. No BLFS book page for this -- a separate GNOME project
# from adwaita-icon-theme itself, split out precisely because modern Adwaita
# (49.0, already built here) dropped its old comprehensive non-symbolic icon
# set in favor of symbolic-only + per-app icons.
#
# rationale: operator reported pavucontrol missing icons (the "set as
# default" button and others). Traced directly to pavucontrol's own
# devicewidget.ui (icon_name="emblem-default" for that button; also
# "changes-prevent", "audio-volume-muted", "audio-card" elsewhere) -- none of
# which exist anywhere in this host's Adwaita-49.0 (801 icons total, symbolic-
# heavy). Adwaita's own installed index.theme already declares
# `Inherits=AdwaitaLegacy,hicolor` -- GNOME's own intended fallback for
# exactly this situation -- but nothing here had ever installed the
# "AdwaitaLegacy" theme it names. Confirmed live (before writing this) that
# the real gitlab.gnome.org/GNOME/adwaita-icon-theme-legacy project ships
# precisely the missing names (emblem-default, changes-prevent,
# audio-volume-muted, audio-card, and more) at every classic size (16-128px)
# under an index.theme whose own Name= is literally "AdwaitaLegacy" -- once
# installed, GTK's normal theme-inheritance icon lookup picks it up
# automatically; no config change needed on top of this.
#
# Source: download.gnome.org, upstream, matches this host's adwaita-icon-
# theme major version family (46.x is the only release series that exists
# for this project; checked gitlab.gnome.org's own tag list, single tag
# 46.2).
#   adwaita-icon-theme-legacy-46.2.tar.xz
#   sha256 548480f58589a54b72d18833b755b15ffbd567e3187249d74e2e1f8f99f22fb4
#   (matches download.gnome.org's own published .sha256sum file, checked
#   directly, not just trusted from the download)
#
# Same meson build shape as blfs-adwaita-icon-theme.sh, same
# gtk4-update-icon-cache/gtk-update-icon-cache dependency (both already
# present from that build).
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
ls -l /usr/share/icons/AdwaitaLegacy/index.theme
