#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/libical.html
# title  : libical-3.0.20
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ommended GLib-2.86.4 (with GObject Introspection), libxml2-2.15.1, and Vala-0.56.18
#   ctx: (both required for GNOME) Optional Doxygen-1.16.1 (for the API documentation),
#   ctx: Graphviz-14.1.2 (for the API documentation), GTK-Doc-1.35.1 (for the API documentation),
#   ctx: ICU-78.2, PyGObject-3.54.5 (for some tests), and Berkeley DB (deprecated) Installation
#   ctx: of libical Install libical by running the following commands:
mkdir build &&
cd    build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr  \
      -D CMAKE_BUILD_TYPE=Release   \
      -D SHARED_ONLY=yes            \
      -D ICAL_BUILD_DOCS=false      \
      -D GOBJECT_INTROSPECTION=true \
      -D ICAL_GLIB_VAPI=false       \
      .. &&
make -j1

# --- block 1 --------------------------------------------------
#   ctx: If you have Doxygen-1.16.1, Graphviz-14.1.2, and GTK-Doc-1.35.1 installed and wish to
#   ctx: build the API documentation, you should remove the -D ICAL_BUILD_DOCS=false switch and
#   ctx: issue:
#   REVIEWED [drop]: Book's own text is explicitly conditional: 'If you have Doxygen, Graphviz, and GTK-Doc installed and wish to build the API documentation, you should remove the -D ICAL_BUILD_DOCS=false switch and issue: make docs'. None of the three are built anywhere in this project (same class of skip as gtk4/gtkmm4's doc blocks above); the extractor classified it as unconditional because the conditional prose sits in the paragraph before the command rather than gating it structurally, the same classifier gap PRACTICES.md already documents for mandatory-install false positives -- here it went the other way, an optional block extracted as mandatory.
# make docs

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue: make test. Now, as the root user:
make install

# --- block 3 --------------------------------------------------
#   ctx: If you have built the API documentation, install by issuing, as root user:
#   REVIEWED [drop]: Depends on block 1's doc build, which is dropped above -- book's own text: 'If you have built the API documentation, install by issuing...'. apidocs/html never exists without it.
# install -vdm755 /usr/share/doc/libical-3.0.20/html &&
# cp -vr apidocs/html/* /usr/share/doc/libical-3.0.20/html

