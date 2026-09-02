#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/x/libnotify.html
# title  : libnotify-0.8.8
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: GObject Introspection) Optional Gi-DocGen-2026.1 and xmlto-0.0.29 (for documentation),
#   ctx: dbusmock-0.38.1 and xvfb-run (to run the test suite) Required (runtime) At least one of
#   ctx: notification-daemon-3.20.0, xfce4-notifyd-0.9.7, or lxqt-notificationd-2.3.1 Note GNOME
#   ctx: Shell and KDE KWin provide their own notification daemons. Installation of libnotify
#   ctx: Install libnotify by running the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=/usr       \
            --buildtype=release \
            -D gtk_doc=false    \
            -D man=false        \
            -D tests=false      \
            -D introspection=disabled \
            ..                  &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: To test the results, you must have the xvfb-run program installed into /usr/bin. If you
#   ctx: have xvfb-run, issue: ninja test to run the tests. If you have Gi-DocGen-2026.1
#   ctx: installed and wish to build the API documentation for this package, issue:
#   REVIEWED [drop]: Optional API-doc generation ('If you have Gi-DocGen installed and wish to build the API documentation, issue...') -- gi-docgen is not part of this build. Same class as the FFmpeg/Doxygen and XWayland doc blocks: true of any host that has not built gi-docgen, not laptop-specific.
# sed "/docs_dir =/s@\$@ / 'libnotify'@" \
#     -i ../docs/reference/meson.build   &&
# meson configure -D gtk_doc=true        &&
# ninja

# --- block 2 --------------------------------------------------
#   ctx: Now, as the root user:
ninja install &&
if [ -e /usr/share/doc/libnotify ]; then
  rm -rf /usr/share/doc/libnotify-0.8.8
  mv -v  /usr/share/doc/libnotify{,-0.8.8}
fi

