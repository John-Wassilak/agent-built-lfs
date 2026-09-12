#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page for the Nextcloud desktop client. BLFS 13.0
# carries no Nextcloud page of any kind (`grep -ril nextcloud book/` returns nothing);
# its only sync-adjacent pages are rsync and Samba.
#
# source: github.com/nextcloud/desktop, tag v34.0.3 (2026-08-26), fetched as GitHub's
# own archive of that tag. Nextcloud publishes no tarball asset and no detached
# signature for the desktop client.
#
# provenance: this is the strongest chain available for this upstream, and it is worth
# stating in full because it is not a plain checksum:
#   1. The v34.0.3 tag is an *annotated, PGP-signed* git tag. Its signature verifies
#      GOOD against RSA key 267BF70F7905C2723B0243267D0F74F05C22F553, uid "Matthieu
#      Gallien" -- Nextcloud's release manager for the desktop client. The key was
#      fetched from keys.openpgp.org by fingerprint, a different origin from the
#      tarball, so this is an independent trust path.
#   2. The signed payload names commit 7563f574a87883f8aa4c42454f795dc9a9c56ca8.
#   3. The archive binds itself to that same commit: `.tag` in the extracted tree
#      contains exactly 7563f574a87883f8aa4c42454f795dc9a9c56ca8, written by git's own
#      export-subst filter at archive time (the tarball's CMakeLists.txt reads that file
#      as its fallback when GIT_SHA1 is unavailable). So the bytes were produced from
#      the commit the signature covers.
#   4. sha256 of the downloaded archive is
#      d0994a9a9d7864d216e51af71d83a7f28382d255470317829ab538cee5aaffcd, recorded so a
#      re-download can be checked against this build.
# Note the archive is NOT byte-identical to the commit tree -- export-subst rewrote
# `.tag` and export-ignore dropped `.gitattributes` -- so a git tree-hash comparison
# does not apply here and was not used.
#
# rationale: operator-requested (2026-09-12) -- "I need the nextcloud client installed,
# the thing that sits in the system tray and syncs directories". That is /usr/bin/
# nextcloud: a Qt6 tray application with a QML main window, a sync engine
# (libnextcloudsync) and a headless nextcloudcmd.
#
# Dependencies, all eight of them new to this system and all read out of the 34.0.3
# CMakeLists files rather than taken from packaging documentation. The three marked
# (*) are the ones no dependency list anywhere would have told you about:
#   Qt6 Core5Compat + Qt5Compat.GraphicalEffects   seq 326
#   Qt6 WebSockets                                 seq 327
#   Extra-CMake-Modules >= 6.0.0                   seq 328 (find_package ECM REQUIRED)
#   KF6Archive                                     seq 329 (REQUIRED in libsync AND gui)
#   qtkeychain                                     seq 330 (#include <qt6keychain/
#                                                   keychain.h> in clientsideencryption)
#   libp11                                       * seq 331 (pkg_check_modules ...
#                                                   REQUIRED, for PKCS#11 E2EE tokens)
#   KDSingleApplication-qt6                        seq 332
#   rsvg-convert                                 * already present from librsvg (seq 91).
#                                                   cmake/modules/GenerateIconsUtils.cmake
#                                                   does find_program(SVG_CONVERTER NAMES
#                                                   inkscape rsvg-convert REQUIRED) and
#                                                   rasterises every state icon at
#                                                   configure time. Without it the build
#                                                   stops with FATAL_ERROR before
#                                                   compiling anything.
# Everything else it wants -- openssl 3.6.1, sqlite 3.51.2, zlib, dbus, glib/gio,
# systemd 259, inotify -- was already here and was confirmed with pkg-config before this
# recipe was written rather than assumed.
#
# Optional dependencies deliberately not built, each checked to be genuinely optional
# (guarded by `if(..._FOUND)` in the source, not merely absent from a README):
#   KF6GuiAddons, KF6DBusAddons   would need the full BLFS frameworks page; see
#                                 recipes/blfs-karchive.sh for why that is not built.
#   KF6KIO                        enables a Dolphin file-manager overlay plugin. There
#                                 is no Dolphin, Nautilus, Nemo or Caja anywhere in this
#                                 repo's package lists.
#   libcloudproviders             a GNOME Files integration; not built here either.
#   libcanberra                   plays the incoming-call ringtone. Absent, so the
#                                 build selects its no-op sound backend and says so
#                                 ("libcanberra not found; notification sounds will be
#                                 silent on this build"). Call notifications still
#                                 appear, silently.
#   Qt6 HttpServer                used only by the test suite, which is off below.
# Qt6 LinguistTools is genuinely optional HERE -- the source guards it with
# `if(Qt6LinguistTools_FOUND)` and its absence would cost the .qm files and nothing else
# -- and was going to be skipped on that basis. It is present anyway, because KArchive
# (seq 329) turned out to require it unconditionally and forced qttools into the plan at
# seq 327.5. So this build does get its ~60 translated .qm files. See
# recipes/blfs-qttools.sh.
#
# Portable: names no device, no filesystem label, no GPU, no /boot path and no sync
# directory. Which server to connect to and which folders to sync are per-user run-time
# state the client keeps in ~/.config/Nextcloud, not build-time configuration -- there is
# nothing here for a host overlay to hold. Shared per CLAUDE.md's shared/host test.
set -e

# Build options. Everything that is not a stock default is here, with the default it
# overrides, because five of this project's defaults are wrong for a from-source system:
#
#   MIRALL_VERSION_SUFFIX=""   VERSION.cmake defaults this to the string "daily", which
#                              is concatenated into MIRALL_VERSION_STRING. Left alone,
#                              a build of the 34.0.3 *release* reports itself as
#                              "34.0.3daily" -- in the About box, in the User-Agent it
#                              sends to the server, and in the version this project's own
#                              `lfsmaint report` would compare against upstream. Emptying
#                              it is what a release build does.
#   BUILD_UPDATER=OFF          NEXTCLOUD.cmake defaults it ON. The updater polls
#                              updates.nextcloud.org and offers to fetch a prebuilt
#                              binary. On a system whose package database is lfsmaint
#                              and whose every binary is built from a recorded recipe,
#                              that is at best a dead end and at worst something that
#                              installs a file no manifest knows about.
#   BUILD_TESTING=OFF          upstream default ON. The suite wants Qt6 HttpServer,
#                              which this host's trimmed qt6 skips.
#   BUILD_SHELL_INTEGRATION_NAUTILUS=OFF
#                              upstream default ON. Installs syncstate.py into
#                              /usr/share/{nautilus,nemo,caja}-python/extensions. None of
#                              those three file managers, and no *-python binding for
#                              them, exists on this system or in any packages.py here --
#                              so ON would add nine inert files to this step's manifest
#                              and to every future audit's cleanup list. One flag to
#                              flip if a file manager is ever built.
#   BUILD_SHELL_INTEGRATION_DOLPHIN=OFF
#                              upstream default ON, but self-disabling: without KF6KIO
#                              its own CMakeLists prints "Dolphin plugin disabled" and
#                              moves on. Stated explicitly so the build log does not
#                              carry a message that reads like a missing dependency.
#
# CMAKE_PREFIX_PATH is needed for exactly one of the dependencies. Qt6 is found without
# help because $QT6DIR/bin is on PATH and cmake searches the prefixes of PATH entries;
# ECM and KDSingleApplication are in /usr. KArchive is in /opt/kf6 and installs no
# binaries, so nothing puts that prefix in cmake's search path -- see
# recipes/blfs-karchive.sh for why it lives there.
cmake -B build -S . \
      -D CMAKE_BUILD_TYPE=Release \
      -D CMAKE_INSTALL_PREFIX=/usr \
      -D CMAKE_PREFIX_PATH="/opt/kf6" \
      -D MIRALL_VERSION_SUFFIX="" \
      -D BUILD_UPDATER=OFF \
      -D BUILD_TESTING=OFF \
      -D BUILD_SHELL_INTEGRATION_NAUTILUS=OFF \
      -D BUILD_SHELL_INTEGRATION_DOLPHIN=OFF

JOBS=$(printf '%s' "${MAKEFLAGS:-}" | grep -oE '\-j ?[0-9]+' | grep -oE '[0-9]+' | head -1 || true)
: "${JOBS:=1}"
echo "### building with --parallel $JOBS (MAKEFLAGS=${MAKEFLAGS:-unset})"
cmake --build build --parallel "$JOBS"

cmake --install build
ldconfig

# GPL-2.0-or-later, and the client links OpenSSL. Installing the license text is the
# obligation, not a courtesy.
install -v -d /usr/share/licenses/nextcloud-desktop
install -v -m644 COPYING /usr/share/licenses/nextcloud-desktop/

# nextcloudcmd, not nextcloud, and the distinction is not cosmetic. The GUI binary
# constructs a QApplication even for --version (its output line "Using Qt platform
# plugin 'wayland'" is the giveaway), so under the driver's `sudo env -i` context --
# root, no DISPLAY, no WAYLAND_DISPLAY, no XDG_RUNTIME_DIR -- it aborts with a core dump
# after the install has already succeeded. That happened on the first run here
# (2026-09-12) and looked far more alarming in the log than it was: the same binary run
# as the desktop user reports 34.0.3 correctly. nextcloudcmd is the headless half of the
# same build and prints the identical version block with no platform plugin at all,
# verified in exactly that empty root environment.
echo "### version"
/usr/bin/nextcloudcmd --version
echo "### tray/session integration installed"
ls -1 /usr/share/applications/com.nextcloud.desktopclient.nextcloud.desktop \
      /usr/lib/systemd/user/com.nextcloud.desktopclient.nextcloud.service
