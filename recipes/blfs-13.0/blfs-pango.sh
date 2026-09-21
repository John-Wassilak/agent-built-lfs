#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/x/pango.html
# title  : Pango-1.57.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: built with FreeType-2.14.1 using harfBuzz-12.3.2), FriBidi-1.0.16, and GLib-2.86.4
#   ctx: (GObject Introspection required for GNOME) Recommended Cairo-1.18.4 (built after
#   ctx: harfBuzz-12.3.2) and Xorg Libraries Optional docutils-0.22.4 (to generate manual pages),
#   ctx: Gi-DocGen-2026.1 (to generate documentation), help2man, libthai, and sysprof
#   ctx: Installation of Pango Install Pango by running the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=/usr            \
            --buildtype=release      \
            --wrap-mode=nofallback   \
            -D introspection=enabled \
            ..                       &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: If you have docutils-0.22.4 installed and wish to build the manual pages for the
#   ctx: installed programs, issue:
#   REVIEWED [drop]: man-pages=true needs docutils (rst2man), not installed.
# meson configure -D man-pages=true &&
# ninja

# --- block 2 --------------------------------------------------
#   ctx: If you have Gi-DocGen-2026.1 installed and wish to build the API documentation for this
#   ctx: package, issue:
#   REVIEWED [drop]: documentation=true needs gi-docgen, not installed.
# sed "/docs_dir =/s@\$@ / 'pango-1.57.0'@" -i ../docs/meson.build &&
# meson configure -D documentation=true                            &&
# ninja

# --- block 3 --------------------------------------------------
#   ctx: To test the results, issue: ninja test. Three tests, test-font-data, test-font, and
#   ctx: test-layout are known to fail due to missing font data. Now, as the root user:
ninja install

