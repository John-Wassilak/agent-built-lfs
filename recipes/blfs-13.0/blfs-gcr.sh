#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/gnome/gcr.html
# title  : Gcr-3.41.2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: sts) Estimated build time: 0.2 SBU (with tests; both using parallelism=4) Gcr
#   ctx: Dependencies Required GLib-2.86.4 (GObject Introspection recommended), libgcrypt-1.12.0,
#   ctx: and p11-kit-0.26.2 Recommended GnuPG-2.5.17, GTK-3.24.51, libsecret-0.21.7,
#   ctx: libxslt-1.1.45, and Vala-0.56.18 Optional Gi-DocGen-2026.1 and Valgrind-3.26.0
#   ctx: Installation of Gcr First, apply a fix for building without OpenSSH installed:
sed '/ssh.add/d; /ssh.agent/d' -i meson.build

# --- block 1 --------------------------------------------------
#   ctx: Install Gcr by running the following commands:
sed -i 's:"/desktop:"/org:' schema/*.xml &&

mkdir build &&
cd    build &&

meson setup --prefix=/usr       \
            --buildtype=release \
            -D gtk_doc=false    \
            -D ssh_agent=false  \
            -D introspection=false \
            ..                  &&
ninja

# --- block 2 --------------------------------------------------
#   ctx: If you have Gi-DocGen-2026.1 installed and wish to build the API documentation for this
#   ctx: package, issue:
#   REVIEWED [drop]: Optional API-doc generation ('If you have Gi-DocGen ... installed and wish to build the API documentation, issue') -- gi-docgen is not part of this build. Same class as the GTK4/gtkmm4/XWayland/libsecret/gcr4 doc blocks.
# sed -e "/install_dir/s@,\$@ / 'gcr-3.41.2'&@" \
#     -i ../docs/*/meson.build                  &&
# meson configure -D gtk_doc=true               &&
# ninja

# --- block 3 --------------------------------------------------
#   ctx: To test the results, issue: ninja test. The tests must be run from an X Terminal or
#   ctx: similar. Now, as the root user:
ninja install

