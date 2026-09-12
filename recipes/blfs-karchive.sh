#!/bin/bash
# HAND-AUTHORED recipe -- BLFS carries no page for an individual KDE framework. Its
# kde/frameworks6.html builds all ~60 of KDE Frameworks 6.23.0 in one scripted step
# (the page's own estimate: 3.0 GB build space, 12 SBU at parallelism=8) and its
# Required list starts breeze-icons, docbook-xml, docbook-xsl-nons, libcanberra,
# libical, lmdb, qca, libqrencode, plasma-wayland-protocols, PyYAML, URI -- none of
# which are built here and none of which KArchive needs.
#
# source: download.kde.org/stable/frameworks/6.23/karchive-6.23.0.tar.xz -- the same
# release directory kde/frameworks6.html itself downloads from, at the same 6.23.0
# the book pins.
#
# provenance: md5 af026d47371ce53861d9690b7fd24f4a, which is the karchive-6.23.0.tar.xz
# line in the `frameworks-6.23.0.md5` file kde/frameworks6.html prints. So this tarball
# is checked against the book's own recorded checksum even though the book has no page
# for it on its own. sha256 of what was downloaded is
# 80f7f3c32a9ec072a650985fca66b20eb8f19a7b10fca44a9d7ad8d8a8645b50.
#
# rationale: nextcloud-desktop (seq 333) does `find_package(KF6Archive REQUIRED)` in
# BOTH src/libsync/CMakeLists.txt and src/gui/CMakeLists.txt and links KF6::Archive into
# each. It is a hard build-time dependency, checked in the 34.0.3 source rather than
# taken from its documentation. The client uses it to read and write the compressed
# archives it ships logs and crash context in.
#
# Operator decision (2026-09-12): build this one framework rather than the book's
# all-frameworks page. The other frameworks nextcloud can use -- KF6GuiAddons,
# KF6DBusAddons, KF6KIO -- are all guarded by `if(..._FOUND)` in its CMakeLists and are
# genuinely optional; KF6KIO would additionally enable a Dolphin overlay plugin, and
# there is no Dolphin, no Nautilus and no other file manager anywhere in this repo's
# package lists.
#
# INSTALL PREFIX is /opt/kf6, not /usr, and that is the decision most likely to be
# questioned later. kde/kf6-intro.html offers both and says "The BLFS editors recommend
# the latter in the BLFS environment". The deciding argument is what happens if the full
# frameworks page is ever built afterwards: it installs to $KF6_PREFIX, defaulting to
# /opt/kf6, and a stray KF6Archive left behind in /usr would then shadow the real one
# for both cmake and ld.so -- the silent, machine-specific breakage CLAUDE.md's whole
# shared/host rule exists to avoid. Installing where the full build would install makes
# that later step a drop-in replacement instead. Extra-CMake-Modules (seq 328) is the
# documented exception and stays in /usr, because the book's own page puts it there.
#
# Portable: names no device, no display, no GPU, no disk. Shared per CLAUDE.md's
# shared/host test.
set -e

KF6_PREFIX=/opt/kf6

# ECM's KDEInstallDirs honours CMAKE_INSTALL_PREFIX for everything, so the only options
# that need stating are the ones whose defaults would change what lands on the system:
#
#   BUILD_TESTING=OFF   ECM's KDECMakeSettings turns testing ON by default. KArchive's
#                       tests need its own test data and add nothing here.
#   WITH_*              bzip2, liblzma, openssl and libzstd all default ON, and ON means
#                       "make it required" rather than "use it if present". All four are
#                       already on this system (bzlib.h, lzma.h 5.8.3, zstd.h 1.5.7,
#                       openssl 3.6.1, all confirmed live before this recipe was
#                       written), so the defaults are correct and are left alone -- but
#                       a host missing any one of them fails here rather than quietly
#                       building a KArchive that cannot read that format.
#   -W no-dev           the book passes this to every KF6-adjacent cmake invocation; it
#                       silences CMake's developer warnings about the upstream project,
#                       which are not actionable from here.
cmake -B build -S . \
      -D CMAKE_BUILD_TYPE=Release \
      -D CMAKE_INSTALL_PREFIX="$KF6_PREFIX" \
      -D BUILD_TESTING=OFF \
      -W no-dev

JOBS=$(printf '%s' "${MAKEFLAGS:-}" | grep -oE '\-j ?[0-9]+' | grep -oE '[0-9]+' | head -1 || true)
: "${JOBS:=1}"
cmake --build build --parallel "$JOBS"

cmake --install build

# Nothing else on the system knows about /opt/kf6 yet. Two pieces of configuration make
# it usable, both lifted from kde/kf6-intro.html's "Installing in /opt" section:
#
#   ld.so.conf   required, not cosmetic. A consumer that installs into /usr (which
#                nextcloud-desktop does) gets no RPATH pointing at /opt/kf6, so without
#                this entry its binary cannot find libKF6Archive.so at run time.
#   profile.d    KF6_PREFIX, for the next build that looks for it.
#
# The book's own /opt block also pathappends eight more directories -- plugins, qml,
# kcms, python site-packages, XDG config and data dirs, GTK modules. They are
# deliberately NOT written here: this install is one library with no plugins, no QML and
# no D-Bus or polkit files, and /etc/profile's pathappend does not check whether a
# directory exists before adding it. If the full frameworks6.html page is ever built,
# replace this file with the book's complete block; the note below says so in place.
if ! grep -q '^/opt/kf6/lib$' /etc/ld.so.conf; then
    cat >> /etc/ld.so.conf << "EOF"

# Begin KF6 addition
/opt/kf6/lib
# End KF6 addition
EOF
fi
ldconfig

cat > /etc/profile.d/kf6.sh << "EOF"
# Begin /etc/profile.d/kf6.sh
#
# Only KF6_PREFIX is set. This system has a single KDE framework installed (KArchive,
# as a dependency of the Nextcloud desktop client), which ships no plugins, no QML and
# no D-Bus or polkit files. If the full BLFS kde/frameworks6.html page is ever built,
# replace this file with the complete "Installing in /opt" block from
# kde/kf6-intro.html -- the pathappend lines for plugins, qml, kcms, PYTHONPATH,
# XDG_CONFIG_DIRS, XDG_DATA_DIRS, GTK_PATH and CPLUS_INCLUDE_PATH -- and add the
# dbus-1/polkit-1/systemd/hicolor symlinks that page creates.
export KF6_PREFIX=/opt/kf6
# End /etc/profile.d/kf6.sh
EOF
chmod 644 /etc/profile.d/kf6.sh

echo "### version"
ls -1 "$KF6_PREFIX"/lib/libKF6Archive.so.* 2>/dev/null | head -2
echo "### cmake package"
ls -d "$KF6_PREFIX"/lib/cmake/KF6Archive
