#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/gnome/libsecret.html
# title  : libsecret-0.21.7
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: 5 (to build manual pages), Valgrind-3.26.0 (can be used in tests), and tpm2-tss (for TPM
#   ctx: support) Optional (Required for the test suite) D-Bus Python-1.4.0, Gjs-1.86.0, and
#   ctx: PyGObject-3.54.5 Required Runtime Dependency gnome-keyring-48.0 Note Any package
#   ctx: requiring libsecret expects GNOME Keyring to be present at runtime. Installation of
#   ctx: libsecret Install libsecret by running the following commands:
mkdir bld &&
cd    bld &&

meson setup --prefix=/usr       \
            --buildtype=release \
            -D gtk_doc=false    \
            -D vapi=false       \
            -D manpage=false    \
            ..                  &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: If you have Gi-DocGen-2026.1 installed and wish to build the API documentation for this
#   ctx: package, issue:
#   REVIEWED [drop]: Optional API-doc generation ('If you have Gi-DocGen ... installed and wish to build the API documentation, issue') -- gi-docgen is not part of this build. Same class as the GTK4/gtkmm4/XWayland doc blocks: true of any host that has not built gi-docgen.
# sed "s/api_version_major/'0.21.7'/"            \
#     -i ../docs/reference/libsecret/meson.build &&
# meson configure -D gtk_doc=true                &&
# ninja

# --- block 2 --------------------------------------------------
#   ctx: Now, as the root user:
ninja install

