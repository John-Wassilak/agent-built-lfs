#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/glib2.html
# title  : GLib-2.86.4
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: e use of an environment variable, GLIB_LOG_LEVEL, that suppresses unwanted messages. The
#   ctx: value of the variable is a digit that corresponds to: 1 Alert 2 Critical 3 Error 4
#   ctx: Warning 5 Notice For instance export GLIB_LOG_LEVEL=4 will skip output of Warning and
#   ctx: Notice messages (and Info/Debug messages if they are turned on). If GLIB_LOG_LEVEL is
#   ctx: not defined, normal message output will not be affected.
patch -Np1 -i ../glib-skip_warnings-1.patch

# --- block 1 --------------------------------------------------
#   ctx: Warning If a previous version of glib is installed, move the headers out of the way so
#   ctx: that later packages do not encounter conflicts:
if [ -e /usr/include/glib-2.0 ]; then
    rm -rf /usr/include/glib-2.0.old &&
    mv -vf /usr/include/glib-2.0{,.old}
fi

# --- block 2 --------------------------------------------------
#   ctx: First, fix a memory corruption problem exposed by glibc-2.43:
patch -Np1 -i ../glib-2.86.4-upstream_fixes-1.patch

# --- block 3 --------------------------------------------------
#   ctx: Install GLib by running the following commands:
mkdir build &&
cd    build &&

meson setup ..                  \
      --prefix=/usr             \
      --buildtype=release       \
      -D introspection=disabled \
      -D glib_debug=disabled    \
      -D man-pages=disabled     \
      -D sysprof=disabled       &&
ninja

# --- block 4 --------------------------------------------------
#   ctx: The GLib test suite requires desktop-file-utils for some tests. However,
#   ctx: desktop-file-utils requires GLib in order to compile; therefore, you must first install
#   ctx: GLib and then run the test suite. As the root user, install this package for the first
#   ctx: time to allow building GObject Introspection:
ninja install

# --- block 5 --------------------------------------------------
#   ctx: Build GObject Introspection:
tar xf ../../gobject-introspection-1.86.0.tar.xz &&

meson setup gobject-introspection-1.86.0 gi-build \
            --prefix=/usr --buildtype=release     &&
ninja -C gi-build

# --- block 6 --------------------------------------------------
#   ctx: To test the results of GObject Introspection, issue: ninja -C gi-build test. As the root
#   ctx: user, install GObject Introspection for generating the introspection data of GLib
#   ctx: libraries (required by various packages using Glib, especially some GNOME packages):
ninja -C gi-build install

# --- block 7 --------------------------------------------------
#   ctx: Now generate the introspection data:
meson configure -D introspection=enabled &&
ninja

# --- block 8 --------------------------------------------------
#   ctx: If you have Gi-DocGen-2026.1 installed and wish to build the API documentation for this
#   ctx: package, issue:
#   REVIEWED [drop]: Builds HTML documentation (-D documentation=true), needs rst2html5 (from docutils). Same root cause as block 3's man-pages fix -- docutils deliberately skipped, one-level policy. Block 9's final 'ninja install' still runs and installs the introspection-enabled build from block 7.
# sed "/docs_dir =/s|$| / 'glib-' + meson.project_version()|" \
#     -i ../docs/reference/meson.build                        &&
# meson configure -D documentation=true                       &&
# ninja

# --- block 9 --------------------------------------------------
#   ctx: If the GLIB_LOG_LEVEL environment variable is set, unset it before running the tests.
#   ctx: Also one file that was created in the first install instruction above needs to be
#   ctx: writable. As the root user, run chmod a+rw .ninja_log. To test the results, issue:
#   ctx: LC_ALL=C ninja test as a non-root user. As the root user, install this package again for
#   ctx: the introspection data (and optionally, the documentation):
ninja install

