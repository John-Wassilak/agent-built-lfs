#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/general/librsvg.html
# title  : librsvg-2.62.3
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: he system certificate store may need to be set up with make-ca-1.16.1 before building
#   ctx: this package. Recommended gdk-pixbuf-2.44.7, GLib-2.88.3 (with GObject Introspection),
#   ctx: and Vala-0.56.19 Optional dav1d-1.5.4 (to support embedded AVIF in SVG), docutils-0.23
#   ctx: (for man pages), and Gi-DocGen-2026.1 (for documentation) Installation of librsvg First,
#   ctx: fix the installation path of the API documentation:
sed -e "/OUTDIR/s|,| / 'librsvg-2.62.3', '--no-namespace-dir',|" \
    -e '/output/s|Rsvg-2.0|librsvg-2.62.3|'                      \
    -i doc/meson.build

# --- block 1 --------------------------------------------------
#   ctx: Install librsvg by running the following commands:
_restore_resolv() {
    rm -f /etc/resolv.conf
    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
}
trap _restore_resolv EXIT
rm -f /etc/resolv.conf
printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > /etc/resolv.conf

mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release -D pixbuf-loader=enabled .. &&
ninja

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue:
#   REVIEWED [drop]: Test suite (meson test -v) -- skipped, matches every other package in this build.
# meson test -v

# --- block 3 --------------------------------------------------
#   ctx: One test named text-text-03-b is known to fail with pango 1.58.1 or newer. Now, as the
#   ctx: root user:
ninja install

