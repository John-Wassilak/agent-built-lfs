#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/gnome/gcr4.html
# title  : Gcr-4.4.0.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: kit-0.26.2 Recommended GnuPG-2.5.17, GTK-4.20.3, libsecret-0.21.7, libxslt-1.1.45, and
#   ctx: Vala-0.56.18 Optional Gi-DocGen-2026.1, GnuTLS-3.8.12, OpenSSH-10.2p1, and
#   ctx: Valgrind-3.26.0 Installation of Gcr Note Both gcr-3 and gcr-4 are coinstallable. This
#   ctx: version of the package is used to support GTK-4 applications, such as gnome-shell-49.4
#   ctx: and Epiphany-49.2. Install Gcr by running the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=/usr       \
            --buildtype=release \
            -D gtk_doc=false    \
            -D vapi=false       \
            ..                  &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: If you have Gi-DocGen-2026.1 installed and wish to build the API documentation for this
#   ctx: package, issue:
#   REVIEWED [drop]: Optional API-doc generation ('If you have Gi-DocGen ... installed and wish to build the API documentation, issue') -- gi-docgen is not part of this build. Same class as the GTK4/gtkmm4/XWayland doc blocks: true of any host that has not built gi-docgen.
# sed -e "/install_dir/s@,\$@ / 'gcr-4.4.0.1'&@" \
#     -i ../docs/*/meson.build                 &&
# meson configure -D gtk_doc=true              &&
# ninja

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue: ninja test. The tests must be run from an X Terminal or
#   ctx: similar. Now, as the root user:
ninja install

