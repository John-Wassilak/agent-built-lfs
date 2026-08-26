#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/x/at-spi2-core.html
# title  : at-spi2-core-2.58.3
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: d size: 572 KB Estimated disk space required: 22 MB (with tests) Estimated build time:
#   ctx: 0.5 SBU (with tests) At-Spi2 Core Dependencies Required dbus-1.16.2, GLib-2.86.4
#   ctx: (GObject Introspection required for GNOME), gsettings-desktop-schemas-49.1 (Runtime),
#   ctx: and Xorg Libraries Optional Gi-DocGen-2026.1 and sphinx-9.1.0 Installation of At-Spi2
#   ctx: Core Install At-Spi2 Core by running the following commands:
mkdir build &&
cd    build &&

meson setup ..                  \
      --prefix=/usr             \
      --buildtype=release       \
      -D gtk2_atk_adaptor=false &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: Now, as the root user:
ninja install

